extends Node2D

@export var move_speed: float = 96.0
@export var distance: float = 192.0
@export var wait_duration: float = 1.0
@export var move_horizontal: bool = true

@onready var platform: AnimatableBody2D = $platform

var _start_position: Vector2
var _target_position: Vector2
var _tween: Tween


func _ready() -> void:
	_start_position = platform.position
	var direction := Vector2.RIGHT if move_horizontal else Vector2.UP
	_target_position = _start_position + direction * distance
	_start_movement()


func _start_movement() -> void:
	if _tween:
		_tween.kill()

	var duration := distance / move_speed

	_tween = create_tween()
	_tween.set_loops()

	_tween.tween_interval(wait_duration)

	_tween.tween_property(platform, "position", _target_position, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	_tween.tween_interval(wait_duration)

	_tween.tween_property(platform, "position", _start_position, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
