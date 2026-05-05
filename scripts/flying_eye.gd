extends CharacterBody2D

@export var fly_speed: float = 55.0
@export var max_hp: int = 2
@export var start_direction: int = -1
@export var enemy_score: int = 150
@export var hover_amplitude: float = 5.0
@export var hover_frequency: float = 1.4
@export var ledge_ray_forward: float = 8.0
@export var ledge_ray_depth: float = 240.0

const FADE_DELAY    := 1.2
const FADE_DURATION := 0.55
const ACCELERATION  := 600.0
const FALL_GRAVITY_MULTIPLIER := 1.0

var hp: int
var direction: int = -1
var is_stunned: bool = false
var is_dead: bool = false
var _hover_t: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim: AnimatedSprite2D = $anim
@onready var collision: CollisionShape2D = $collision
@onready var wall_detector: RayCast2D = $wall_detector
@onready var ground_detector: RayCast2D = $ground_detector
@onready var hitbox_collision: CollisionShape2D = $hitbox/collision2


func _ready() -> void:
	direction = sign(start_direction)
	if direction == 0:
		direction = -1
	hp = max_hp
	_update_visual_direction()
	anim.play("fly")


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.y += _gravity * FALL_GRAVITY_MULTIPLIER * delta
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
		move_and_slide()
		return

	if is_stunned:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
		velocity.y = move_toward(velocity.y, 0, ACCELERATION * delta)
		move_and_slide()
		return

	_hover_t += delta
	var hover_v := cos(_hover_t * hover_frequency * TAU) * hover_amplitude * hover_frequency * TAU

	velocity.x = float(direction) * fly_speed
	velocity.y = hover_v

	move_and_slide()

	var should_flip := false
	if wall_detector and wall_detector.is_colliding():
		should_flip = true
	if not should_flip and is_on_wall():
		should_flip = true
	if not should_flip and ground_detector:
		ground_detector.position.x = ledge_ray_forward * float(direction)
		ground_detector.target_position = Vector2(0, ledge_ray_depth)
		ground_detector.force_raycast_update()
		if not ground_detector.is_colliding():
			should_flip = true
	if should_flip:
		_flip()


func _flip() -> void:
	direction *= -1
	if wall_detector:
		wall_detector.scale.x *= -1
	_update_visual_direction()


func _update_visual_direction() -> void:
	if anim:
		anim.flip_h = direction == -1


func take_stomp_damage() -> void:
	if is_dead or is_stunned:
		return
	hp -= 1
	if hp <= 0:
		die()
	else:
		_play_hit()


func _play_hit() -> void:
	is_stunned = true
	anim.play("hit")
	var sf: SpriteFrames = anim.sprite_frames
	var duration := 0.4
	if sf and sf.has_animation("hit"):
		duration = float(sf.get_frame_count("hit")) / maxf(sf.get_animation_speed("hit"), 0.01)
	await get_tree().create_timer(duration + 0.05).timeout

	if not is_instance_valid(self) or is_dead:
		return
	is_stunned = false
	anim.play("fly")


func die() -> void:
	if is_dead:
		return
	is_dead = true
	is_stunned = false
	_disable_hitbox_collision()
	collision.set_deferred("disabled", true)
	velocity = Vector2.ZERO

	anim.play("hurt")
	var sf: SpriteFrames = anim.sprite_frames
	var anim_duration := 0.5
	if sf and sf.has_animation("hurt"):
		anim_duration = float(sf.get_frame_count("hurt")) / maxf(sf.get_animation_speed("hurt"), 0.01)
	await get_tree().create_timer(anim_duration + FADE_DELAY).timeout

	_fade_and_free()


func _disable_hitbox_collision() -> void:
	if hitbox_collision:
		hitbox_collision.set_deferred("disabled", true)


func _fade_and_free() -> void:
	if not is_instance_valid(self):
		return
	var tw := create_tween()
	tw.tween_property(anim, "modulate:a", 0.0, FADE_DURATION)
	await tw.finished
	if not is_instance_valid(self):
		return
	Globals.score += enemy_score
	queue_free()


func _on_anim_animation_finished(_anim_name: StringName = "") -> void:
	pass
