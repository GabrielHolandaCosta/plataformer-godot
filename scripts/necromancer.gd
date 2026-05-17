extends EnemyBase
class_name NecromancerBoss

# ----------------------------------------------------------------------------
# Boss Necromancer — A Sombra Cinzenta
# ----------------------------------------------------------------------------
# Boss final do jogo. Reúne os mesmos princípios do Khorvan mas adiciona
# o mecanismo de summon: durante o combate ele invoca esqueletos pra
# sobrecarregar o player.
#
# Recebe dano só quando o player pula em cima da cabeça (hitbox Area2D).
#
# Fluxo do encontro:
#   INTRO_IDLE → player entra na trigger
#   → INTRO_WALK (anda até o herói; player travado)
#   → INTRO_DIALOG (revelação: ele é o Sombra Cinzenta)
#   → IDLE / APPROACH / SLASH1 / SUMMON / TELEPORT / HURT
#   → quando hp <= 0: DEFEAT_DIALOG → DEAD
# ----------------------------------------------------------------------------

@export var max_hp: int = 12
@export var approach_speed: float = 64.0
@export var attack_score: int = 5000
@export var stomp_invuln_time: float = 0.58
@export var slash_range: float = 38.0
@export var idle_pause_time: float = 0.68
@export var aggro_range: float = 360.0

# Summon: a cada N ciclos de ataque ele invoca um esqueleto. Max esqueletos
# vivos simultaneamente é limitado pra não atravancar a tela.
@export var summon_every_n: int = 3
@export var max_active_skeletons: int = 1
@export var summon_offset_x: float = 36.0

# Teleport: ele desaparece e reaparece do outro lado do player, pra forçar
# o player a virar e perseguir. Usado a cada N ciclos quando enraged.
@export var teleport_chance: float = 0.25
@export var teleport_distance: float = 92.0

# Fase 2 (HP <= metade): boss enraged.
@export var enraged_speed_mult: float = 1.18
@export var enraged_idle_mult: float = 0.75
@export var enraged_color := Color(1.2, 0.7, 0.7, 1.0)
@export var base_color := Color(1.0, 1.0, 1.0, 1.0)

# espada / golpe corpo a corpo: deslocamento à frente + janela ativa.
@export var sword_offset_x: float = 18.0
@export var sword_active_delay: float = 0.28
@export var sword_active_duration: float = 0.22

# distância em que o boss para na entrada para conversar com o herói
@export var intro_stop_distance: float = 64.0
@export var intro_walk_speed: float = 42.0

# áudio
@export var battle_music_target_db: float = -14.0
@export var bg_music_target_db: float = -15.0
@export var music_fade_time: float = 1.4

const FACESET_NECRO := "res://assets/Necromancer/faceset/faceset.png"
const FACESET_HERO := "res://assets/hero/faceset/faceset.png"
const TITLE_NECRO := "Sombra Cinzenta"
const TITLE_HERO := "Guardião"

const DIALOG_SCENE := preload("res://prefabs/dialog_screen.tscn")
const SKELETON_SCENE := preload("res://actors/skeleton.tscn")

enum State {
	INTRO_IDLE,
	INTRO_WALK,
	INTRO_DIALOG,
	IDLE,
	APPROACH,
	SLASH1,
	SUMMON,
	TELEPORT,
	HURT,
	DEFEAT_DIALOG,
	DEAD,
}

const FADE_DELAY := 1.6
const FADE_DURATION := 0.7

var hp: int
var state: int = State.INTRO_IDLE
var state_timer: float = 0.0
var attack_cycle: int = 0
var is_invulnerable: bool = false
var battle_started: bool = false
var dialog_active: bool = false
var defeat_started: bool = false

var sword_active: bool = false
var _sword_phase_timer: float = 0.0

var enraged: bool = false

var _active_skeletons: Array = []

signal boss_defeated()

@onready var asp: AnimatedSprite2D = $anim
@onready var hitbox_collision: CollisionShape2D = $hitbox/collision2
@onready var trigger_area: Area2D = $trigger
@onready var battle_music: AudioStreamPlayer = $battle_music
@onready var sword_hurtbox: StaticBody2D = $sword_hurtbox
@onready var sword_collision: CollisionShape2D = $sword_hurtbox/collision
@onready var summon_fx: CPUParticles2D = $summon_fx


func _ready() -> void:
	super._ready()
	hp = max_hp
	enemy_score = attack_score
	move_speed = approach_speed
	if trigger_area and not trigger_area.body_entered.is_connected(_on_trigger_body_entered):
		trigger_area.body_entered.connect(_on_trigger_body_entered)
	_set_sword_active(false)
	_sync_sword_position()
	state = State.INTRO_IDLE
	if asp:
		asp.modulate = base_color
	_play("idle")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		_apply_gravity(delta)
		move_and_slide()
		return

	state_timer -= delta
	_tick_sword(delta)
	_update_facing_player()

	match state:
		State.INTRO_IDLE:
			_state_intro_idle(delta)
		State.INTRO_WALK:
			_state_intro_walk(delta)
		State.INTRO_DIALOG:
			_state_dialog_lock(delta)
		State.IDLE:
			_state_idle(delta)
		State.APPROACH:
			_state_approach(delta)
		State.SLASH1:
			_state_slash(delta)
		State.SUMMON:
			_state_summon(delta)
		State.TELEPORT:
			_state_teleport(delta)
		State.HURT:
			_state_hurt(delta)
		State.DEFEAT_DIALOG:
			_state_dialog_lock(delta)


# ----------------------------------------------------------------------------
# Estados
# ----------------------------------------------------------------------------

func _state_intro_idle(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	move_and_slide()


func _state_intro_walk(delta: float) -> void:
	_apply_gravity(delta)
	var dir := _direction_to_player()
	if dir != 0.0:
		direction = int(dir)
		_update_visual_direction()
	var dist := _distance_to_player()
	if dist <= intro_stop_distance:
		velocity.x = move_toward(velocity.x, 0, acceleration * 2.0 * delta)
		move_and_slide()
		if abs(velocity.x) < 5.0:
			_change_state(State.INTRO_DIALOG)
		return
	var target_speed := float(direction) * intro_walk_speed
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	move_and_slide()


func _state_dialog_lock(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, acceleration * 2.0 * delta)
	move_and_slide()


func _state_idle(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	move_and_slide()
	if state_timer <= 0.0:
		_choose_next_action()


func _state_approach(delta: float) -> void:
	_apply_gravity(delta)
	var dir := _direction_to_player()
	if dir != 0.0:
		direction = int(dir)
		_update_visual_direction()
	var target_speed: float = float(direction) * approach_speed
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	move_and_slide()
	if _distance_to_player() <= slash_range:
		_change_state(State.SLASH1)
	elif state_timer <= 0.0:
		_change_state(State.IDLE)


func _state_slash(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	move_and_slide()


func _state_summon(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, acceleration * 2.0 * delta)
	move_and_slide()


func _state_teleport(delta: float) -> void:
	# Boss fica intangível durante o teleport (pulo curto pra trás).
	_apply_gravity(delta)
	move_and_slide()


func _state_hurt(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, acceleration * 2.0 * delta)
	move_and_slide()
	if state_timer <= 0.0:
		is_invulnerable = false
		set_collision_layer_value(3, true)
		if asp:
			asp.modulate = enraged_color if enraged else base_color
		_change_state(State.IDLE)


# ----------------------------------------------------------------------------
# Transições
# ----------------------------------------------------------------------------

func _change_state(new_state: int) -> void:
	state = new_state
	match new_state:
		State.INTRO_IDLE:
			state_timer = 0.0
			_play("idle")
		State.INTRO_WALK:
			state_timer = 0.0
			_play("run")
		State.INTRO_DIALOG:
			state_timer = 0.0
			_play("idle")
			_start_intro_dialog()
		State.IDLE:
			state_timer = idle_pause_time
			_play("idle")
		State.APPROACH:
			state_timer = 1.4
			_play("run")
		State.SLASH1:
			state_timer = 0.0
			velocity.x = 0
			_start_sword_swing()
			_play("attack1")
		State.SUMMON:
			state_timer = 0.0
			velocity.x = 0
			_play("attack2")
			_do_summon()
		State.TELEPORT:
			state_timer = 0.0
			is_invulnerable = true
			_set_sword_active(false)
			_play("jump")
			_do_teleport()
		State.HURT:
			state_timer = stomp_invuln_time
			is_invulnerable = true
			if asp:
				asp.modulate = Color(1, 0.4, 0.4, 1)
				asp.scale = Vector2(0.74, 0.66)
				var tw := create_tween()
				tw.tween_property(asp, "scale", Vector2(0.7, 0.7), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			velocity = Vector2.ZERO
			_set_sword_active(false)
			_play("hurt")
		State.DEFEAT_DIALOG:
			state_timer = 0.0
			is_invulnerable = true
			enraged = false
			velocity = Vector2.ZERO
			_disable_hitbox_collision()
			_set_sword_active(false)
			if asp:
				asp.modulate = Color(0.6, 0.4, 0.85, 1)
			_play("hurt")
			_start_defeat_dialog()
		State.DEAD:
			_set_sword_active(false)


func _choose_next_action() -> void:
	attack_cycle += 1
	var dist := _distance_to_player()

	# Summon a cada N ciclos (se houver espaço)
	if attack_cycle % summon_every_n == 0 and _active_skeleton_count() < max_active_skeletons:
		_change_state(State.SUMMON)
		return

	# Em fase enraged, pode teleportar
	if enraged and randf() < teleport_chance:
		_change_state(State.TELEPORT)
		return

	if dist > aggro_range:
		_change_state(State.APPROACH)
		return

	if dist <= slash_range:
		_change_state(State.SLASH1)
	else:
		_change_state(State.APPROACH)


# ----------------------------------------------------------------------------
# Trigger / cena de entrada
# ----------------------------------------------------------------------------

func _on_trigger_body_entered(body: Node) -> void:
	if state != State.INTRO_IDLE:
		return
	if not body.is_in_group("player"):
		return
	body.set("can_move", false)
	body.velocity = Vector2.ZERO
	# Espera o player aterrissar antes de iniciar a cena (evita bug de
	# flutuação se ele estava no ar quando entrou na trigger).
	_begin_intro_after_landing(body)


func _begin_intro_after_landing(body: Node) -> void:
	await _wait_player_grounded(2.0)
	if not is_instance_valid(self) or state != State.INTRO_IDLE:
		return
	_change_state(State.INTRO_WALK)


# ----------------------------------------------------------------------------
# Diálogo de intro — revela quem ele é e o plano dele
# ----------------------------------------------------------------------------

func _start_intro_dialog() -> void:
	if dialog_active or battle_started:
		return
	dialog_active = true
	# Garante que o player segue travado e parado durante a fala
	var p := _player_node()
	if p and p is CharacterBody2D:
		p.set("can_move", false)
		(p as CharacterBody2D).velocity = Vector2.ZERO

	var lines := [
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Você chegou mais longe do que qualquer um antes, Guardião…"},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "A Vessa. O Khorvan. Cada um deles era um pedaço meu. E mesmo assim você seguiu em frente."},
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "Quem é você?"},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Eu sou o que sussurrava nos seus pesadelos. Eu sou a Sombra Cinzenta."},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Fui eu quem queimou as árvores. Fui eu quem afastou os animais. O desmatamento, o fogo… cada cinza dessa floresta carrega meu nome."},
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "Por quê?! A floresta não te fez nada!"},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Não se trata do que ela fez. Trata-se do que ela impede."},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Esse mundo é velho demais. Verde demais. Cheio de raízes que recusam a mudança."},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Eu vou queimar tudo. E sobre as cinzas, vou erguer um mundo NOVO — um mundo que obedeça a mim."},
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "Você é só um covarde com medo de algo que não pode controlar."},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Então prove. Levante essa lâmina, Guardião. Mostre se a sua floresta vale o seu sangue."},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Levantem-se, meus servos. Vamos receber o herói."},
	]
	var data := {}
	for i in lines.size():
		data[i] = lines[i]

	var dialog := DIALOG_SCENE.instantiate()
	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.add_child(dialog)
	else:
		get_tree().root.add_child(dialog)
	dialog.start(data)
	dialog.tree_exited.connect(_on_intro_dialog_finished)


func _on_intro_dialog_finished() -> void:
	dialog_active = false
	battle_started = true
	var p := _player_node()
	if p:
		p.set("can_move", true)
	_start_battle_music()
	_change_state(State.IDLE)


# ----------------------------------------------------------------------------
# Música de batalha
# ----------------------------------------------------------------------------

func _find_bg_music() -> AudioStreamPlayer:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var node := scene.get_node_or_null("bg_music")
	if node and node is AudioStreamPlayer:
		return node
	return null


func _fade_audio(stream_player: AudioStreamPlayer, target_db: float, duration: float, stop_at_end: bool) -> void:
	if stream_player == null or not is_instance_valid(stream_player):
		return
	var tw := create_tween()
	tw.tween_property(stream_player, "volume_db", target_db, duration)
	if stop_at_end:
		tw.tween_callback(stream_player.stop)


func _start_battle_music() -> void:
	var bg := _find_bg_music()
	if bg:
		_fade_audio(bg, -80.0, music_fade_time, true)
	if battle_music:
		battle_music.volume_db = -80.0
		battle_music.play()
		_fade_audio(battle_music, battle_music_target_db, music_fade_time, false)


func _restore_bg_music() -> void:
	if battle_music and battle_music.playing:
		_fade_audio(battle_music, -80.0, music_fade_time, true)
	var bg := _find_bg_music()
	if bg:
		if not bg.playing:
			bg.volume_db = -80.0
			bg.play()
		_fade_audio(bg, bg_music_target_db, music_fade_time, false)


# ----------------------------------------------------------------------------
# Summon
# ----------------------------------------------------------------------------

func _do_summon() -> void:
	# Cleanup de referências mortas
	_active_skeletons = _active_skeletons.filter(func(s): return is_instance_valid(s))

	if summon_fx:
		summon_fx.restart()
		summon_fx.emitting = true

	var spawn_offset := summon_offset_x * float(direction)
	var spawn_pos := global_position + Vector2(spawn_offset, -2)

	var skel := SKELETON_SCENE.instantiate()
	# Aponta o esqueleto pra direção do player e liga o modo follow_player.
	var dir_to_player := _direction_to_player()
	skel.start_direction = int(dir_to_player) if dir_to_player != 0.0 else direction
	skel.set("follow_player", true)
	skel.set("chase_speed", 60.0)
	# Define position antes do add — fica como local; o pai está em (0,0).
	skel.position = spawn_pos
	skel.modulate = Color(0.85, 0.7, 1.0, 1.0)
	get_parent().call_deferred("add_child", skel)
	_active_skeletons.append(skel)


func _active_skeleton_count() -> int:
	_active_skeletons = _active_skeletons.filter(func(s): return is_instance_valid(s))
	return _active_skeletons.size()


# ----------------------------------------------------------------------------
# Teleport
# ----------------------------------------------------------------------------

func _do_teleport() -> void:
	var p := _player_node()
	if p == null:
		is_invulnerable = false
		_change_state(State.IDLE)
		return
	# Reaparece do lado oposto do player
	var dir_to_player := _direction_to_player()
	var new_x: float = p.global_position.x + dir_to_player * teleport_distance
	# Pequeno fade
	if asp:
		var tw := create_tween()
		tw.tween_property(asp, "modulate:a", 0.0, 0.18)
		tw.tween_callback(func():
			global_position.x = new_x
			velocity = Vector2.ZERO
			direction = -int(dir_to_player) if dir_to_player != 0.0 else direction
			_update_visual_direction()
		)
		tw.tween_property(asp, "modulate:a", 1.0, 0.20)
		tw.tween_callback(func():
			is_invulnerable = false
			_change_state(State.IDLE)
		)
	else:
		global_position.x = new_x
		is_invulnerable = false
		_change_state(State.IDLE)


# ----------------------------------------------------------------------------
# Auxiliares
# ----------------------------------------------------------------------------

func _play(anim_name: String) -> void:
	if asp == null:
		return
	if asp.animation != anim_name:
		asp.play(anim_name)


func _player_node() -> Node2D:
	if Globals.player and is_instance_valid(Globals.player):
		return Globals.player
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		return nodes[0]
	return null


func _direction_to_player() -> float:
	var p := _player_node()
	if p == null:
		return 0.0
	return sign(p.global_position.x - global_position.x)


func _distance_to_player() -> float:
	var p := _player_node()
	if p == null:
		return 99999.0
	return global_position.distance_to(p.global_position)


func _update_facing_player() -> void:
	if state in [State.IDLE, State.APPROACH, State.SLASH1, State.SUMMON, State.INTRO_WALK, State.INTRO_DIALOG, State.DEFEAT_DIALOG]:
		var d := _direction_to_player()
		if d != 0.0:
			direction = int(d)
			_update_visual_direction()


func _update_visual_direction() -> void:
	if asp:
		asp.flip_h = direction == -1
	_sync_sword_position()


func _sync_sword_position() -> void:
	if sword_hurtbox:
		sword_hurtbox.position.x = sword_offset_x * float(direction)


# ----------------------------------------------------------------------------
# Hitbox da espada
# ----------------------------------------------------------------------------

func _start_sword_swing() -> void:
	sword_active = false
	_sword_phase_timer = sword_active_delay
	if sword_collision:
		sword_collision.set_deferred("disabled", true)


func _tick_sword(delta: float) -> void:
	if state != State.SLASH1:
		if sword_active:
			_set_sword_active(false)
		return
	_sword_phase_timer -= delta
	if _sword_phase_timer <= 0.0:
		if not sword_active:
			_set_sword_active(true)
			_sword_phase_timer = sword_active_duration
		else:
			_set_sword_active(false)
			_sword_phase_timer = INF


func _set_sword_active(active: bool) -> void:
	sword_active = active
	if sword_collision:
		sword_collision.set_deferred("disabled", not active)


# ----------------------------------------------------------------------------
# Dano por pisada e morte
# ----------------------------------------------------------------------------

func take_stomp_damage() -> void:
	if state == State.DEAD or state == State.DEFEAT_DIALOG or is_invulnerable:
		return
	if not battle_started:
		return
	hp -= 1
	if hp <= 0:
		_change_state(State.DEFEAT_DIALOG)
		return
	if not enraged and hp <= int(ceil(float(max_hp) / 2.0)):
		_enter_enraged()
	_change_state(State.HURT)


func _enter_enraged() -> void:
	enraged = true
	approach_speed *= enraged_speed_mult
	move_speed = approach_speed
	idle_pause_time *= enraged_idle_mult
	if asp:
		asp.modulate = enraged_color


func die() -> void:
	if state == State.DEAD or state == State.DEFEAT_DIALOG:
		return
	_change_state(State.DEFEAT_DIALOG)


func _start_defeat_dialog() -> void:
	if defeat_started:
		return
	defeat_started = true
	# Mata todos os esqueletos remanescentes
	for skel in _active_skeletons:
		if not is_instance_valid(skel):
			continue
		if skel.is_inside_tree() and skel.has_method("die"):
			skel.die()
		else:
			skel.queue_free()

	await _wait_player_grounded(1.5)
	dialog_active = true
	var p := _player_node()
	if p and p is CharacterBody2D:
		p.set("can_move", false)
		(p as CharacterBody2D).velocity = Vector2.ZERO

	var lines := [
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Impossível… eu sou a sombra de TUDO… eu sou… o que vem depois…"},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Sem mim… não há mudança… não há fim… não há…"},
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "A floresta não precisa de você pra mudar. Ela já sabia mudar antes de você existir."},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Talvez… talvez você esteja certo, Guardião…"},
		{"title": TITLE_NECRO, "faceset": FACESET_NECRO, "dialog": "Cuide dela… por mim… também…"},
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "Vou cuidar. Por todos vocês."},
	]
	var data := {}
	for i in lines.size():
		data[i] = lines[i]

	var dialog := DIALOG_SCENE.instantiate()
	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.add_child(dialog)
	else:
		get_tree().root.add_child(dialog)
	dialog.start(data)
	dialog.tree_exited.connect(_on_defeat_dialog_finished)


func _wait_player_grounded(timeout_s: float) -> void:
	var p := _player_node()
	if p == null or not (p is CharacterBody2D):
		return
	var cb := p as CharacterBody2D
	var elapsed := 0.0
	while elapsed < timeout_s and is_instance_valid(cb) and not cb.is_on_floor():
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()


func _on_defeat_dialog_finished() -> void:
	dialog_active = false
	var p := _player_node()
	if p:
		p.set("can_move", true)
	_finish_death()


func _finish_death() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	is_invulnerable = true
	_disable_hitbox_collision()
	collision.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	_play("death")
	if asp:
		asp.modulate = Color(0.5, 0.3, 0.7, 1)
	_restore_bg_music()

	await get_tree().create_timer(FADE_DELAY).timeout
	if not is_instance_valid(self):
		return
	var tw := create_tween()
	tw.tween_property(asp, "modulate:a", 0.0, FADE_DURATION)
	await tw.finished
	if not is_instance_valid(self):
		return
	Globals.score += enemy_score
	Globals.mark_boss_defeated("necromancer")
	emit_signal("boss_defeated")
	queue_free()


func _on_anim_animation_finished(_anim_name: StringName = "") -> void:
	if state == State.DEAD:
		return
	if asp == null:
		return
	match asp.animation:
		"attack1":
			if battle_started and state == State.SLASH1:
				_change_state(State.IDLE)
		"attack2":
			if battle_started and state == State.SUMMON:
				_change_state(State.IDLE)
