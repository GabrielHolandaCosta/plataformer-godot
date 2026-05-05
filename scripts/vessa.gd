extends EnemyBase
class_name VessaBoss

# ----------------------------------------------------------------------------
# Boss Vessa
# ----------------------------------------------------------------------------
# Recebe dano apenas quando o player pula em cima da cabeça (hitbox Area2D).
#
# Fluxo do encontro:
#   INTRO_IDLE → player entra na área de trigger
#   → INTRO_WALK (Vessa caminha até o herói, ele fica imóvel)
#   → INTRO_DIALOG (diálogo de apresentação)
#   → IDLE / CHASE / CROUCH / JUMP / DRILL / DASH / HURT (combate, com música)
#   → quando hp <= 0: morte direta com fade da música, voltando para a bg.
# ----------------------------------------------------------------------------

@export var max_hp: int = 8
@export var chase_speed: float = 55.0
@export var dash_speed: float = 140.0
@export var jump_velocity: float = -330.0
@export var jump_horizontal_speed: float = 90.0
@export var drill_fall_speed: float = 420.0
@export var attack_score: int = 1500
@export var stomp_invuln_time: float = 0.6
@export var dash_duration: float = 1.4
@export var idle_pause_time: float = 0.9
@export var aggro_range: float = 320.0

# distância em que a Vessa para na entrada para conversar com o herói
@export var intro_stop_distance: float = 48.0
@export var intro_walk_speed: float = 40.0

# áudio
@export var battle_music_target_db: float = -15.0
@export var bg_music_target_db: float = -15.0
@export var music_fade_time: float = 1.4

const FACESET_VESSA := "res://assets/Sprite Pack 8/5 - Vessa/Falling (32 x 32).png"
const FACESET_HERO := "res://assets/Sprite Pack 2/2 - Mr. Mochi/Hurt (32 x 32).png"
const TITLE_VESSA := "Vessa"
const TITLE_HERO := "Guardião"

const DIALOG_SCENE := preload("res://prefabs/dialog_screen.tscn")

enum State {
	INTRO_IDLE,
	INTRO_WALK,
	INTRO_DIALOG,
	IDLE,
	CHASE,
	CROUCH,
	JUMP,
	FALL,
	DRILL_START,
	DRILL,
	DRILL_END_AERIAL,
	DRILL_END_GROUNDED,
	LANDED,
	DASH,
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
var has_started_drill: bool = false
var battle_started: bool = false
var dialog_active: bool = false
var defeat_started: bool = false

@onready var asp: AnimatedSprite2D = $anim
@onready var hitbox_collision: CollisionShape2D = $hitbox/collision2
@onready var trigger_area: Area2D = $trigger
@onready var battle_music: AudioStreamPlayer = $battle_music


func _ready() -> void:
	super._ready()
	hp = max_hp
	enemy_score = attack_score
	move_speed = chase_speed
	if trigger_area and not trigger_area.body_entered.is_connected(_on_trigger_body_entered):
		trigger_area.body_entered.connect(_on_trigger_body_entered)
	state = State.INTRO_IDLE
	_play("idle")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		_apply_gravity(delta)
		move_and_slide()
		return

	state_timer -= delta
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
		State.CHASE:
			_state_chase(delta)
		State.CROUCH:
			_state_crouch(delta)
		State.JUMP:
			_state_jump(delta)
		State.FALL:
			_state_fall(delta)
		State.DRILL_START:
			_state_drill_start(delta)
		State.DRILL:
			_state_drill(delta)
		State.DRILL_END_AERIAL:
			_state_drill_end_aerial(delta)
		State.DRILL_END_GROUNDED:
			_state_drill_end_grounded(delta)
		State.LANDED:
			_state_landed(delta)
		State.DASH:
			_state_dash(delta)
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
		_choose_next_attack()


func _state_chase(delta: float) -> void:
	_apply_gravity(delta)
	flip_direction()
	var target_speed: float = float(direction) * chase_speed
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	move_and_slide()
	if state_timer <= 0.0:
		_change_state(State.CROUCH)


func _state_crouch(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	move_and_slide()
	if state_timer <= 0.0:
		_start_jump_attack()


func _state_jump(delta: float) -> void:
	_apply_gravity(delta)
	move_and_slide()
	if velocity.y >= -10.0:
		_change_state(State.FALL)


func _state_fall(delta: float) -> void:
	_apply_gravity(delta)
	move_and_slide()
	if not has_started_drill and state_timer <= 0.0:
		has_started_drill = true
		_change_state(State.DRILL_START)
	elif is_on_floor():
		_change_state(State.LANDED)


func _state_drill_start(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	velocity.y += gravity * 0.4 * delta
	move_and_slide()
	if state_timer <= 0.0:
		_change_state(State.DRILL)
	elif is_on_floor():
		_change_state(State.DRILL_END_GROUNDED)


func _state_drill(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	velocity.y = drill_fall_speed
	move_and_slide()
	if is_on_floor():
		_change_state(State.DRILL_END_GROUNDED)


func _state_drill_end_aerial(delta: float) -> void:
	_apply_gravity(delta)
	move_and_slide()
	if is_on_floor():
		_change_state(State.DRILL_END_GROUNDED)
	elif state_timer <= 0.0:
		_change_state(State.FALL)


func _state_drill_end_grounded(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, acceleration * 2.0 * delta)
	_apply_gravity(delta)
	move_and_slide()
	if state_timer <= 0.0:
		has_started_drill = false
		_change_state(State.IDLE)


func _state_landed(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	_apply_gravity(delta)
	move_and_slide()
	if state_timer <= 0.0:
		has_started_drill = false
		_change_state(State.IDLE)


func _state_dash(delta: float) -> void:
	_apply_gravity(delta)
	flip_direction()
	var target_speed: float = float(direction) * dash_speed
	velocity.x = move_toward(velocity.x, target_speed, acceleration * 1.5 * delta)
	move_and_slide()
	if state_timer <= 0.0 or (wall_detector and wall_detector.is_colliding()):
		_change_state(State.IDLE)


func _state_hurt(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, acceleration * 2.0 * delta)
	move_and_slide()
	if state_timer <= 0.0:
		is_invulnerable = false
		asp.modulate = Color(1, 1, 1, 1)
		has_started_drill = false
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
			_play("walk")
		State.INTRO_DIALOG:
			state_timer = 0.0
			_play("idle")
			_start_intro_dialog()
		State.IDLE:
			state_timer = idle_pause_time
			_play("idle")
		State.CHASE:
			state_timer = 1.6
			move_speed = chase_speed
			_play("walk")
		State.CROUCH:
			state_timer = 0.32
			velocity.x = 0
			_play("crouch")
		State.JUMP:
			var dir_to_player := _direction_to_player()
			velocity.y = jump_velocity
			velocity.x = dir_to_player * jump_horizontal_speed
			direction = int(sign(dir_to_player)) if dir_to_player != 0.0 else direction
			_update_visual_direction()
			has_started_drill = false
			state_timer = 0.0
			_play("jump")
		State.FALL:
			state_timer = 0.18
			_play("fall")
		State.DRILL_START:
			state_timer = 0.25
			velocity.x = 0
			_play("drill_start")
		State.DRILL:
			state_timer = 0.0
			_play("drill")
		State.DRILL_END_AERIAL:
			state_timer = 0.4
			_play("drill_end_aerial")
		State.DRILL_END_GROUNDED:
			state_timer = 0.6
			velocity = Vector2.ZERO
			_play("drill_end_grounded")
		State.LANDED:
			state_timer = 0.18
			_play("landed")
		State.DASH:
			state_timer = dash_duration
			move_speed = dash_speed
			direction = int(sign(_direction_to_player())) if _direction_to_player() != 0.0 else direction
			_update_visual_direction()
			_play("walk")
			if asp:
				asp.speed_scale = 2.0
		State.HURT:
			state_timer = stomp_invuln_time
			is_invulnerable = true
			asp.modulate = Color(1, 0.4, 0.4, 1)
			# Knockback: pula e recua na direção contrária ao player, criando
			# espaço pra evitar que o player fique stompando infinito.
			var knock_dir := -_direction_to_player()
			if knock_dir == 0.0:
				knock_dir = float(-direction)
			velocity.x = knock_dir * 180.0
			velocity.y = -200.0
			_play("hurt")
		State.DEFEAT_DIALOG:
			state_timer = 0.0
			is_invulnerable = true
			velocity = Vector2.ZERO
			_disable_hitbox_collision()
			asp.modulate = Color(1, 1, 1, 1)
			_play("defeated_pose")
			_start_defeat_dialog()
		State.DEAD:
			pass

	if new_state != State.DASH and asp:
		asp.speed_scale = 1.0


func _choose_next_attack() -> void:
	attack_cycle += 1
	var dist := _distance_to_player()
	if dist > aggro_range:
		_change_state(State.CHASE)
		return
	if attack_cycle % 2 == 0:
		_change_state(State.DASH)
	else:
		_change_state(State.CROUCH)


func _start_jump_attack() -> void:
	_change_state(State.JUMP)


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
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "Você não é desta floresta… o cheiro de cinzas que você carrega entrega tudo."},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Ahn… então é você o tal Guardião? Imaginei algo… maior."},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Eu vim apenas confirmar uma coisa. E parece que cheguei exatamente no lugar certo."},
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "Confirmar o quê? Quem mandou você?"},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Você fala como quem ainda não entendeu o que está acontecendo aqui."},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Existe alguém muito acima de você, Guardião. Alguém cuja voz a floresta inteira já começou a obedecer."},
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "…A floresta nunca obedeceu ninguém além de si mesma."},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "É justamente por isso que ele a quer. E é por isso que eu estou aqui."},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Eu não preciso te derrotar. Só preciso te atrasar até que seja tarde demais."},
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "Então não vai ter conversa. Se quer me atrasar… vai ter que tentar."},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Não diga que não te avisei, Guardião. Você nem imagina contra o que está prestes a se levantar."},
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
	if state in [State.CHASE, State.IDLE, State.CROUCH, State.DASH, State.INTRO_WALK, State.INTRO_DIALOG, State.DEFEAT_DIALOG]:
		var d := _direction_to_player()
		if d != 0.0:
			direction = int(d)
			_update_visual_direction()


func _update_visual_direction() -> void:
	if asp:
		asp.flip_h = direction == 1


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
	else:
		_change_state(State.HURT)


func die() -> void:
	# Compatibilidade com EnemyBase: encaminha para a sequência de derrota.
	if state == State.DEAD or state == State.DEFEAT_DIALOG:
		return
	_change_state(State.DEFEAT_DIALOG)


func _start_defeat_dialog() -> void:
	if defeat_started:
		return
	defeat_started = true
	# Espera o player aterrissar antes de travar o controle, evitando que
	# ele fique parado no ar caso o stomp final tenha acontecido em pleno pulo.
	await _wait_player_grounded(1.5)
	dialog_active = true
	var p := _player_node()
	if p and p is CharacterBody2D:
		p.set("can_move", false)
		(p as CharacterBody2D).velocity = Vector2.ZERO
	var lines := [
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Hah… então… você é mesmo… o Guardião…"},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Mas não comemore. Eu sou apenas… o primeiro de muitos."},
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "Quem mandou você? Fala."},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Não posso… dizer o nome dele. Mesmo aqui, ele escuta."},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Mas você já o sentiu, não foi? Aquela presença… atrás de cada árvore queimada."},
		{"title": TITLE_HERO,  "faceset": FACESET_HERO,  "dialog": "…Sim. Eu senti."},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Então você sabe que isso… ainda está só começando."},
		{"title": TITLE_VESSA, "faceset": FACESET_VESSA, "dialog": "Cuide bem dessa sua floresta… enquanto ela ainda for sua."},
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
	_play("hurt")
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
	Globals.mark_boss_defeated("vessa")
	queue_free()


func _on_anim_animation_finished(_anim_name: StringName = "") -> void:
	if state == State.DEAD:
		return
	if asp == null:
		return
	match asp.animation:
		"landed":
			has_started_drill = false
			if battle_started:
				_change_state(State.IDLE)
		"drill_end_grounded":
			has_started_drill = false
			if battle_started:
				_change_state(State.IDLE)
