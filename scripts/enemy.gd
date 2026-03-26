extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 40.0
@export var acceleration: float = 900.0
@export var gravity_multiplier: float = 1.0
@export var start_direction: int = -1
@export var enemy_score := 100

var wall_detector: RayCast2D
var texture: Sprite2D
@onready var anim: Node = $anim
@onready var collision: CollisionShape2D = $collision

var direction: int = -1
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dead: bool = false

var can_spawn: bool = false
var spawn_instance: PackedScene
var spawn_instance_position: Node2D

var _scored_out: bool = false


func _ready() -> void:
	direction = sign(start_direction)
	if direction == 0:
		direction = -1
	wall_detector = get_node_or_null("wall_detector") as RayCast2D
	texture = get_node_or_null("texture") as Sprite2D
	_update_visual_direction()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * gravity_multiplier * delta


func flip_direction() -> void:
	if not wall_detector:
		return
	if wall_detector.is_colliding():
		direction *= -1
		wall_detector.scale.x *= -1
		_update_visual_direction()


func movement(delta: float) -> void:
	var target_speed := direction * move_speed
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	move_and_slide()


func _update_visual_direction() -> void:
	if texture:
		if direction == 1:
			texture.flip_h = true
		else:
			texture.flip_h = false


func _disable_hitbox_collision() -> void:
	if has_node("hitbox/collision2"):
		$hitbox/collision2.set_deferred("disabled", true)
	elif has_node("hitbox/collision"):
		$hitbox/collision.set_deferred("disabled", true)
	elif has_node("hitbox/CollisionShape2D"):
		$hitbox/CollisionShape2D.set_deferred("disabled", true)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	collision.set_deferred("disabled", true)
	_disable_hitbox_collision()
	velocity = Vector2.ZERO
	if anim is AnimationPlayer:
		(anim as AnimationPlayer).play("hurt")
	elif anim is AnimatedSprite2D:
		var asp := anim as AnimatedSprite2D
		asp.play("hurt")
		_schedule_hurt_kill_fallback(asp)


func _schedule_hurt_kill_fallback(asp: AnimatedSprite2D) -> void:
	var sf := asp.sprite_frames
	if sf == null or not sf.has_animation("hurt"):
		return
	var fps := sf.get_animation_speed("hurt")
	var frame_count := sf.get_frame_count("hurt")
	var duration := float(frame_count) / maxf(fps, 0.01)
	get_tree().create_timer(duration + 0.08).timeout.connect(_on_hurt_animation_fallback_timeout)


func _on_hurt_animation_fallback_timeout() -> void:
	if not is_instance_valid(self) or _scored_out or not is_dead:
		return
	if anim is AnimatedSprite2D and (anim as AnimatedSprite2D).animation == "hurt":
		kill_and_score()


func spawn_new_enemy() -> void:
	if spawn_instance == null or spawn_instance_position == null:
		return
	var instance_scene := spawn_instance.instantiate()
	get_tree().root.add_child(instance_scene)
	instance_scene.global_position = spawn_instance_position.global_position


func kill_and_score() -> void:
	if _scored_out:
		return
	_scored_out = true
	Globals.score += enemy_score
	if can_spawn:
		spawn_new_enemy()
	queue_free()


func _on_anim_animation_finished(anim_name: StringName = "") -> void:
	if not is_dead:
		return
	var hurt_done := false
	if anim is AnimationPlayer:
		hurt_done = anim_name == "hurt"
	elif anim is AnimatedSprite2D:
		hurt_done = (anim as AnimatedSprite2D).animation == "hurt"
	if hurt_done:
		kill_and_score()
