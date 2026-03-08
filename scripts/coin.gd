extends Area2D

@export var bob_height: float = 4.0
@export var bob_speed: float = 3.0
@export var rotate_speed: float = 1.5

@onready var anim: AnimatedSprite2D = $anim
@onready var collision: CollisionShape2D = $collision

var collected: bool = false
var time_passed: float = 0.0
var base_y: float = 0.0


func _ready() -> void:
	base_y = position.y
	
	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")


func _process(delta: float) -> void:
	if collected:
		return
	
	time_passed += delta
	position.y = base_y + sin(time_passed * bob_speed) * bob_height
	rotation = sin(time_passed * rotate_speed) * 0.08


func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	
	# pode deixar assim por enquanto
	if body.name != "player":
		return
	
	collect_coin()


func collect_coin() -> void:
	collected = true
	collision.set_deferred("disabled", true)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.08)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_property(self, "position:y", position.y - 10.0, 0.18)

	if anim.sprite_frames.has_animation("collect"):
		anim.play("collect")
	else:
		await tween.finished
		queue_free()


func _on_anim_animation_finished() -> void:
	if collected and anim.animation == "collect":
		queue_free()
