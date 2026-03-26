extends Area2D

var transition: Node = null
@export var next_level: String = ""
var is_switching: bool = false

func _ready() -> void:
	transition = get_tree().current_scene.get_node_or_null("transition")

func _on_body_entered(body: Node) -> void:
	if is_switching:
		return
	if not body.is_in_group("player"):
		return
	if next_level == "":
		print("No Scene Loaded")
		return

	is_switching = true
	if transition != null and transition.has_method("change_scene"):
		transition.call("change_scene", next_level)
		return

	var error := get_tree().change_scene_to_file(next_level)
	if error != OK:
		is_switching = false
		push_error("Failed to change scene to: %s" % next_level)
