extends AnimatableBody2D

@onready var anim := $anim as AnimationPlayer
@onready var respawn_timer := $respawn_timer as Timer
@onready var respawn_position := global_position

@export var respawn_delay := 3.0

var velocity := Vector2.ZERO
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_triggered := false


func _ready():
	set_physics_process(false)


func _physics_process(delta):
	velocity.y += gravity * delta
	position += velocity * delta


func has_collided_with(collision: KinematicCollision2D, collider: CharacterBody2D):
	if !is_triggered:
		is_triggered = true
		anim.play("shake")
		velocity = Vector2.ZERO


func _on_anim_animation_finished(anim_name):
	if anim_name == "shake":
		set_physics_process(true)
		respawn_timer.start(respawn_delay)


func _on_respawn_timer_timeout():
	set_physics_process(false)
	global_position = respawn_position
	velocity = Vector2.ZERO

	$texture.scale = Vector2(0.2, 0.2)
	$texture.modulate = Color(1, 1, 1, 0.4)

	var spawn_tween = create_tween()
	spawn_tween.set_parallel(true)
	spawn_tween.tween_property($texture, "scale", Vector2(1, 1), 0.25)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	spawn_tween.tween_property($texture, "modulate:a", 1.0, 0.2)

	is_triggered = false
