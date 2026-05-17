extends Control
class_name DialogScreen

var _step: float = 0.05
var _id: int = 0
var data: Dictionary = {}

var is_typing := false
# Geração da animação de digitação atual. Cada vez que avançamos pra próxima
# linha, incrementamos esse contador. Se um loop de digitação antigo
# continuar rodando depois disso (porque ainda estava no await create_timer),
# ele compara a sua geração com a atual e desiste — assim duas digitações
# nunca brigam pelo mesmo Label.
var _typing_gen: int = 0
var _closed: bool = false

@export var _name: Label
@export var _dialog: RichTextLabel
@export var _faceset: TextureRect


func _ready():
	add_to_group("dialog")

	modulate.a = 0.0

	# Força posicionamento no centro-inferior da tela após o layout resolver
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	position = Vector2(vp.x / 2.0 - 160.0, vp.y - 100.0)
	size = Vector2(320.0, 80.0)

	_fade_in()


func start(data_input: Dictionary):
	data = data_input
	_id = 0
	_initialize_dialog()


func _process(_delta):
	if _closed or data.is_empty():
		return

	if Input.is_action_pressed("interact") and is_typing:
		_step = 0.01
	else:
		_step = 0.05

	if Input.is_action_just_pressed("interact"):

		if is_typing:
			_dialog.visible_characters = _dialog.text.length()
			is_typing = false
			# Mata o loop de digitação corrente — incrementar a geração faz
			# o while interno desistir na próxima iteração.
			_typing_gen += 1
			return

		_id += 1

		if _id >= data.size():
			_closed = true
			# Invalida qualquer typing pendente
			_typing_gen += 1
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.can_move = true

			await _fade_out()
			if is_instance_valid(self):
				queue_free()
			return

		_initialize_dialog()


func _initialize_dialog():
	if _closed or not is_inside_tree():
		return
	# Nova geração — se um typing antigo ainda estiver no await, ele vai
	# comparar e ver que não é mais o atual, desistindo.
	_typing_gen += 1
	var my_gen := _typing_gen
	is_typing = true

	var entry = data[_id]

	_name.text = entry["title"]
	_dialog.text = entry["dialog"]
	_faceset.texture = load(entry["faceset"])

	_dialog.visible_characters = 0

	while _dialog.visible_characters < _dialog.text.length():
		var tree := get_tree()
		if tree == null:
			return
		await tree.create_timer(_step).timeout
		# Pode ter sido fechado / nova linha começou enquanto esperava.
		if _closed or not is_instance_valid(self) or not is_inside_tree():
			return
		if my_gen != _typing_gen:
			return
		_dialog.visible_characters += 1

	if my_gen == _typing_gen:
		is_typing = false


func _fade_in():
	modulate.a = 0.0
	var tree := get_tree()
	if tree == null:
		return
	var tween := tree.create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)


func _fade_out():
	var tree := get_tree()
	if tree == null:
		return
	var tween := tree.create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
