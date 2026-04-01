extends CharacterBody2D

enum State { PATROL, ATTACK, HURT }

const FIREBALL_SCENE: PackedScene = preload("res://prefabs/fireball.tscn")
const MOUTH_OFFSET := Vector2(10.0, -6.0)
const FIREBALL_SPAWN_TIME := 0.32
const HURT_DURATION := 0.45
const STOMP_SCORE := 150

var move_speed := 50.0
var direction := 1
var health_points := 2

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
const LEDGE_FORWARD := 6.0
const LEDGE_DOWN := 14.0

var state: State = State.PATROL
var _hurt_timer: float = 0.0
var _spawned_this_attack: bool = false
var _dying: bool = false

@onready var sprite = $sprite
@onready var anim = $anim as AnimationPlayer
@onready var fireball_spawn_point = $fireball_spawn_point as Marker2D
@onready var ground_detector = $ground_detector as RayCast2D
@onready var player_detector = $player_detector as RayCast2D


func _ready() -> void:
	_sync_mouth()
	anim.animation_finished.connect(_on_anim_animation_finished)


func _physics_process(delta: float) -> void:
	match state:
		State.PATROL:
			_patrol_physics(delta)
		State.ATTACK:
			_attack_physics(delta)
		State.HURT:
			_hurt_physics(delta)


func _patrol_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	velocity.x = move_speed * float(direction)
	move_and_slide()

	var need_flip := false
	if is_on_wall():
		need_flip = true
	elif is_on_floor() and ground_detector:
		ground_detector.position.x = LEDGE_FORWARD * float(direction)
		ground_detector.target_position = Vector2(0, LEDGE_DOWN)
		ground_detector.force_raycast_update()
		if not ground_detector.is_colliding():
			need_flip = true

	if need_flip:
		_flip()

	_update_player_detection()
	if _sees_player():
		state = State.ATTACK
		_spawned_this_attack = false
		velocity.x = 0
		anim.play("shooting")


func _attack_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	velocity.x = move_toward(velocity.x, 0, 800.0 * delta)
	move_and_slide()

	if anim.current_animation == "shooting" and anim.current_animation_position >= FIREBALL_SPAWN_TIME and not _spawned_this_attack:
		spawn_fireball()

	_update_player_detection()


func _hurt_physics(delta: float) -> void:
	if _dying:
		sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
		velocity.x = move_toward(velocity.x, 0, 800.0 * delta)
		move_and_slide()
		return

	sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	velocity.x = move_toward(velocity.x, 0, 800.0 * delta)
	move_and_slide()
	_hurt_timer -= delta
	if _hurt_timer <= 0.0:
		sprite.modulate = Color.WHITE
		state = State.PATROL
		anim.play("running")


func _update_player_detection() -> void:
	player_detector.force_raycast_update()


func _sees_player() -> bool:
	if not player_detector.is_colliding():
		return false
	var c = player_detector.get_collider()
	return c != null and c.is_in_group("player")


func spawn_fireball() -> void:
	if state != State.ATTACK:
		return
	if _spawned_this_attack:
		return
	_spawned_this_attack = true
	var fb := FIREBALL_SCENE.instantiate() as CharacterBody2D
	fb.direction = direction
	fb.global_position = fireball_spawn_point.global_position
	get_parent().add_child(fb)


func take_stomp_damage() -> void:
	health_points -= 1
	state = State.HURT
	velocity.x = 0
	_spawned_this_attack = false
	sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	anim.play("hurt")

	if health_points <= 0:
		_dying = true
		var hurt_len: float = anim.get_animation("hurt").length
		await get_tree().create_timer(hurt_len).timeout
		if not is_instance_valid(self):
			return
		sprite.modulate = Color.WHITE
		Globals.score += STOMP_SCORE
		queue_free()
		return

	_hurt_timer = HURT_DURATION


func _flip() -> void:
	direction *= -1
	sprite.scale.x *= -1
	player_detector.scale.x *= -1
	_sync_mouth()


func _sync_mouth() -> void:
	fireball_spawn_point.position = Vector2(MOUTH_OFFSET.x * float(direction), MOUTH_OFFSET.y)


func _on_anim_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shooting" and state == State.ATTACK:
		if _sees_player():
			_spawned_this_attack = false
			anim.play("shooting")
		else:
			state = State.PATROL
			anim.play("running")
