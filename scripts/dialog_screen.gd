extends Control
class_name DialogScreen

var _step: float = 0.05
var _id: int = 0
var data: Dictionary = {}

var is_typing := false

@export var _name: Label
@export var _dialog: RichTextLabel
@export var _faceset: TextureRect


func _ready():
	add_to_group("dialog")

	modulate.a = 0.0

	# Força posicionamento no centro-inferior da tela após o layout resolver
	await get_tree().process_frame
	var vp := get_viewport_rect().size
	position = Vector2(vp.x / 2.0 - 160.0, vp.y - 100.0)
	size = Vector2(320.0, 80.0)

	_fade_in()


func start(data_input: Dictionary):
	data = data_input
	_id = 0
	_initialize_dialog()


func _process(_delta):
	if data.is_empty():
		return

	if Input.is_action_pressed("interact") and is_typing:
		_step = 0.01
	else:
		_step = 0.05

	if Input.is_action_just_pressed("interact"):

		if is_typing:
			_dialog.visible_characters = _dialog.text.length()
			is_typing = false
			return

		_id += 1

		if _id >= data.size():
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.can_move = true

			await _fade_out()
			queue_free()
			return

		_initialize_dialog()


func _initialize_dialog():
	is_typing = true

	var entry = data[_id]

	_name.text = entry["title"]
	_dialog.text = entry["dialog"]
	_faceset.texture = load(entry["faceset"])

	_dialog.visible_characters = 0

	while _dialog.visible_characters < _dialog.text.length():
		await get_tree().create_timer(_step).timeout
		_dialog.visible_characters += 1

	is_typing = false

func _fade_in():
	modulate.a = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func _fade_out():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
