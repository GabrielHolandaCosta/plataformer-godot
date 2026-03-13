extends CharacterBody2D

@export var move_speed: float = 40.0
@export var acceleration: float = 900.0
@export var gravity_multiplier: float = 1.0
@export var start_direction: int = -1
@export var enemy_score := 100

@onready var wall_detector: RayCast2D = $wall_detector
@onready var texture: Sprite2D = $texture
@onready var anim: AnimationPlayer = $anim
@onready var collision: CollisionShape2D = $collision

var direction: int = -1
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dead: bool = false


func _ready() -> void:
	direction = sign(start_direction)
	if direction == 0:
		direction = -1
	
	_update_visual_direction()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_apply_gravity(delta)
	_handle_turn()
	_move_horizontal(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * gravity_multiplier * delta


func _handle_turn() -> void:
	if wall_detector.is_colliding():
		turn_around()


func _move_horizontal(delta: float) -> void:
	var target_speed := direction * move_speed
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)


func turn_around() -> void:
	direction *= -1
	wall_detector.target_position.x *= -1
	_update_visual_direction()


func _update_visual_direction() -> void:
	texture.flip_h = direction > 0


func die() -> void:
	if is_dead:
		return
		
	print("die chamado")
	is_dead = true
	collision.set_deferred("disabled", true)
	$hitbox/collision2.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	anim.play("hurt")


func _on_anim_animation_finished(anim_name: StringName) -> void:
	if is_dead and anim_name == "hurt":
		Globals.score += enemy_score
		queue_free()
