extends EnemyBase
class_name KhorvanBoss

# ----------------------------------------------------------------------------
# Boss Khorvan — A Lâmina do Cinzento
# ----------------------------------------------------------------------------
# Recebe dano apenas quando o player pula em cima da cabeça (hitbox Area2D).
#
# Fluxo do encontro:
#   INTRO_IDLE → player entra na área de trigger
#   → INTRO_WALK (Khorvan caminha até o herói, ele fica imóvel)
#   → INTRO_DIALOG (diálogo de apresentação)
#   → IDLE / APPROACH / SLASH1 / SLASH2 / LEAP / FALL / HURT (combate)
#   → quando hp <= 0: DEFEAT_DIALOG → DEAD com fade.
# ----------------------------------------------------------------------------

@export var max_hp: int = 14
@export var approach_speed: float = 80.0
@export var leap_velocity: float = -340.0
@export var leap_horizontal_speed: float = 140.0
@export var attack_score: int = 3000
@export var stomp_invuln_time: float = 0.75
@export var slash_range: float = 36.0
@export var leap_chance: int = 2                 # leap a cada N ciclos
@export var idle_pause_time: float = 0.40
@export var aggro_range: float = 320.0

# fase 2 (HP <= metade): boss enraged, com cor avermelhada e tempos reduzidos.
@export var enraged_speed_mult: float = 1.30
@export var enraged_idle_mult: float = 0.55
@export var enraged_color := Color(1.0, 0.78, 0.78, 1.0)

# espada: deslocamento à frente do corpo + janela ativa do golpe.
# attack1/attack2 têm 6 frames a 12 fps (≈0.50s). O impacto visual cai
# no frame ~3-4, então a hitbox ativa de 0.28s a 0.50s do início do swing.
@export var sword_offset_x: float = 22.0
@export var sword_active_delay: float = 0.28
@export var sword_active_duration: float = 0.22

# distância em que o Khorvan para na entrada para conversar com o herói
@export var intro_stop_distance: float = 56.0
@export var intro_walk_speed: float = 38.0

# áudio
@export var battle_music_target_db: float = -14.0
@export var bg_music_target_db: float = -15.0
@export var music_fade_time: float = 1.4

const FACESET_KHORVAN := "res://assets/Martial Hero/khorvan_face.tres"
const FACESET_HERO := "res://assets/Sprite Pack 2/2 - Mr. Mochi/Hurt (32 x 32).png"
const TITLE_KHORVAN := "Khorvan"
const TITLE_HERO := "Guardião"

const DIALOG_SCENE := preload("res://prefabs/dialog_screen.tscn")

enum State {
	INTRO_IDLE,
	INTRO_WALK,
	INTRO_DIALOG,
	IDLE,
	APPROACH,
	SLASH1,
	SLASH2,
	LEAP,
	FALL,
	LANDED,
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

@onready var asp: AnimatedSprite2D = $anim
@onready var hitbox_collision: CollisionShape2D = $hitbox/collision2
@onready var trigger_area: Area2D = $trigger
@onready var battle_music: AudioStreamPlayer = $battle_music
@onready var sword_hurtbox: StaticBody2D = $sword_hurtbox
@onready var sword_collision: CollisionShape2D = $sword_hurtbox/collision


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
		State.SLASH2:
			_state_slash(delta)
		State.LEAP:
			_state_leap(delta)
		State.FALL:
			_state_fall(delta)
		State.LANDED:
			_state_landed(delta)
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


func _state_leap(delta: float) -> void:
	_apply_gravity(delta)
	move_and_slide()
	if velocity.y >= -10.0:
		_change_state(State.FALL)


func _state_fall(delta: float) -> void:
	_apply_gravity(delta)
	move_and_slide()
	if is_on_floor():
		_change_state(State.LANDED)


func _state_landed(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, acceleration * 2.0 * delta)
	_apply_gravity(delta)
	move_and_slide()
	if state_timer <= 0.0:
		_change_state(State.IDLE)


func _state_hurt(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, acceleration * 2.0 * delta)
	move_and_slide()
	if state_timer <= 0.0:
		is_invulnerable = false
		asp.modulate = enraged_color if enraged else Color(1, 1, 1, 1)
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
		State.SLASH2:
			state_timer = 0.0
			velocity.x = 0
			_start_sword_swing()
			_play("attack2")
		State.LEAP:
			var dir_to_player := _direction_to_player()
			# Em fase normal recua. Em fase enraged, 50% das vezes pula PARA o player
			# (avanço aéreo agressivo) — quebra o ritmo de quem espera ele se afastar.
			var leap_dir: float
			if enraged and dir_to_player != 0.0 and randf() < 0.5:
				leap_dir = dir_to_player
			else:
				leap_dir = -dir_to_player if dir_to_player != 0.0 else float(-direction)
			velocity.y = leap_velocity
			velocity.x = leap_dir * leap_horizontal_speed
			direction = int(sign(dir_to_player)) if dir_to_player != 0.0 else direction
			_update_visual_direction()
			state_timer = 0.0
			_play("jump")
		State.FALL:
			state_timer = 0.0
			_play("fall")
		State.LANDED:
			state_timer = 0.18
			_play("idle")
		State.HURT:
			state_timer = stomp_invuln_time
			is_invulnerable = true
			asp.modulate = Color(1, 0.4, 0.4, 1)
			velocity.y = -150.0
			_set_sword_active(false)
			_play("hurt")
			# se já está enraged, ao sair de HURT o estado IDLE restaura a cor avermelhada
		State.DEFEAT_DIALOG:
			state_timer = 0.0
			is_invulnerable = true
			enraged = false
			velocity = Vector2.ZERO
			_disable_hitbox_collision()
			_set_sword_active(false)
			asp.modulate = Color(1, 1, 1, 1)
			_play("hurt")
			_start_defeat_dialog()
		State.DEAD:
			_set_sword_active(false)


func _choose_next_action() -> void:
	attack_cycle += 1
	var dist := _distance_to_player()

	# Salto a cada N ciclos para mover o boss e quebrar o ritmo do player
	if attack_cycle % leap_chance == 0:
		_change_state(State.LEAP)
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
	_change_state(State.INTRO_WALK)


# ----------------------------------------------------------------------------
# Diálogo de intro
# ----------------------------------------------------------------------------

func _start_intro_dialog() -> void:
	if dialog_active or battle_started:
		return
	dialog_active = true
	var lines := [
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "A energia dela ainda paira aqui… então é verdade. Você derrotou a Vessa."},
		{"title": TITLE_HERO,    "faceset": FACESET_HERO,    "dialog": "Você a conhecia."},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Conheço cada um que Ele moldou. A Vessa era a curiosidade. A pergunta enviada à frente."},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Eu… sou a resposta."},
		{"title": TITLE_HERO,    "faceset": FACESET_HERO,    "dialog": "Quem é \"Ele\"?"},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Aquele a quem sirvo não tem nome que se pronuncie em voz alta. A floresta queima quando alguém tenta."},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Ele já dormiu sob estas raízes antes mesmo de você nascer, Guardião. E agora… está acordando."},
		{"title": TITLE_HERO,    "faceset": FACESET_HERO,    "dialog": "É por isso que o ar tem cheirado a cinzas."},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Cinza é o que sobra. E o que sobra… pertence a Ele."},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "A Vessa foi um aviso. Eu sou a sentença."},
		{"title": TITLE_HERO,    "faceset": FACESET_HERO,    "dialog": "Então venha, sentença. Eu não vou recuar."},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Levante a cabeça enquanto pode, Guardião. Em breve, não restará nem isso."},
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
	if state in [State.IDLE, State.APPROACH, State.SLASH1, State.SLASH2, State.INTRO_WALK, State.INTRO_DIALOG, State.DEFEAT_DIALOG]:
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
# Hitbox da espada: ativa só durante a janela ofensiva do golpe
# ----------------------------------------------------------------------------

func _start_sword_swing() -> void:
	sword_active = false
	_sword_phase_timer = sword_active_delay
	if sword_collision:
		sword_collision.set_deferred("disabled", true)


func _tick_sword(delta: float) -> void:
	if state != State.SLASH1 and state != State.SLASH2:
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
	# Entra em modo "enraged" quando passa da metade da vida.
	if not enraged and hp <= int(ceil(float(max_hp) / 2.0)):
		_enter_enraged()
	_change_state(State.HURT)


func _enter_enraged() -> void:
	enraged = true
	approach_speed *= enraged_speed_mult
	move_speed = approach_speed
	idle_pause_time *= enraged_idle_mult
	leap_horizontal_speed *= 1.15
	# A cor "raiva" fica fixa durante todo o resto da batalha (exceto frames de stomp,
	# que aplicam o flash vermelho-claro temporário).
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
	# Espera o player aterrissar antes de travar o controle
	await _wait_player_grounded(1.5)
	dialog_active = true
	var p := _player_node()
	if p and p is CharacterBody2D:
		p.set("can_move", false)
		(p as CharacterBody2D).velocity = Vector2.ZERO
	var lines := [
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Impossível… você venceu… duas vezes…"},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Eu fui forjado para ser… o último golpe antes Dele."},
		{"title": TITLE_HERO,    "faceset": FACESET_HERO,    "dialog": "E mesmo assim, eu vou continuar. Diga onde Ele está."},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Ele não está em lugar algum… e está em todos."},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Olhe… para a sua sombra agora. Ela é mais longa do que era ontem, não é?"},
		{"title": TITLE_HERO,    "faceset": FACESET_HERO,    "dialog": "…"},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Você o despertou, Guardião. Hoje. Aqui. Comigo."},
		{"title": TITLE_HERO,    "faceset": FACESET_HERO,    "dialog": "Foi o que precisava ser feito."},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Talvez sim… Talvez nunca tenha existido outra escolha."},
		{"title": TITLE_KHORVAN, "faceset": FACESET_KHORVAN, "dialog": "Tudo o que ainda existia entre você e Ele… acaba de cair com a minha lâmina."},
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
	asp.modulate = Color(1, 0.5, 0.5, 1)
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
	queue_free()


func _on_anim_animation_finished(_anim_name: StringName = "") -> void:
	if state == State.DEAD:
		return
	if asp == null:
		return
	match asp.animation:
		"attack1":
			# Encadeia SLASH2 se ainda perto do player, senão volta a IDLE
			if battle_started and state == State.SLASH1:
				if _distance_to_player() <= slash_range * 1.2:
					_change_state(State.SLASH2)
				else:
					_change_state(State.IDLE)
		"attack2":
			if battle_started and state == State.SLASH2:
				_change_state(State.IDLE)
