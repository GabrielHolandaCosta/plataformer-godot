extends Area2D

@onready var transition: CanvasLayer = get_tree().current_scene.get_node("transition")
@export var next_level: String = ""
var is_switching: bool = false

func _on_body_entered(body: Node) -> void:
	if is_switching:
		return
	if not body.is_in_group("player"):
		return
	if next_level == "":
		print("No Scene Loaded")
		return

	is_switching = true
	transition.change_scene(next_level)
