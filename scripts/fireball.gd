extends CharacterBody2D

const SPEED := 110.0

var direction := 1

@onready var _sprite: Sprite2D = $anim
var _anim_t: float = 0.0


func _ready() -> void:
	add_to_group("Fireball")
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if _sprite:
		_sprite.flip_h = direction < 0
		_anim_t += delta * 12.0
		_sprite.frame = int(_anim_t) % 3
	velocity.x = SPEED * float(direction)
	velocity.y = 0
	move_and_slide()
	if is_on_wall():
		queue_free()
