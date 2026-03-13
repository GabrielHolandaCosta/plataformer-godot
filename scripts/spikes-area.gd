extends Area2D

@onready var collision = $collision as CollisionShape2D
@onready var spikes = $spikes as Sprite2D

func _ready():
	var rect_shape = collision.shape as RectangleShape2D
	if rect_shape:
		rect_shape.size = spikes.get_rect().size


func _on_body_entered(body):
	if body.name == "player" && body.has_method("take_damage"):
		body.take_damage(Vector2(0, -250))
