extends Sprite2D

@onready var anim := $anim as AnimationPlayer
@onready var respawn_timer := $respawn_timer as Timer
@onready var respawn_position := global_position

@export var reset_timer := 3.0

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
	pass # Replace with function body.
