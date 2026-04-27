extends Node2D

## Título que aparece na caixa de diálogo (ex: "Aviso", "Placa", nome do lugar)
@export var sign_title: String = "Aviso"

## Cada entrada do array vira uma página de diálogo (pressionar interact avança)
@export_multiline var dialog_lines: Array[String] = ["O caminho à frente parece instável… fique atento a cada passo."]

## Imagem que aparece como "portrait" no diálogo — padrão: ícone de fala
@export var faceset_path: String = "res://assets/amazon/Platformer_Jungle Asset Pack/sign/sign.png"

@onready var texture: CanvasItem = $texture
@onready var interaction_area: Area2D = $area_sign

var player_inside := false
var float_time := 0.0


func _ready() -> void:
	texture.visible = false
	texture.modulate.a = 0.0
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if not texture.visible:
		return
	float_time += delta
	texture.position.y = -38.0 + sin(float_time * 2.0) * 4.0
	var s := 1.0 + sin(float_time * 3.0) * 0.08
	texture.scale = Vector2(s, s)


func _unhandled_input(_event: InputEvent) -> void:
	if not player_inside:
		return
	if get_tree().get_nodes_in_group("dialog").size() > 0:
		return
	if Input.is_action_just_pressed("interact"):
		_start_dialog()


func _start_dialog() -> void:
	hide_texture()

	var data: Dictionary = {}
	for i in dialog_lines.size():
		data[i] = {
			"faceset": faceset_path,
			"dialog":  dialog_lines[i],
			"title":   sign_title
		}

	var dialog_scene := preload("res://prefabs/dialog_screen.tscn")
	var dialog := dialog_scene.instantiate()

	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.add_child(dialog)
	else:
		get_tree().root.add_child(dialog)

	dialog.start(data)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = true
	if get_tree().get_nodes_in_group("dialog").size() == 0:
		show_texture()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = false
	hide_texture()


func show_texture() -> void:
	texture.visible = true
	var tween := create_tween()
	tween.tween_property(texture, "modulate:a", 1.0, 0.25)


func hide_texture() -> void:
	var tween := create_tween()
	tween.tween_property(texture, "modulate:a", 0.0, 0.2)
	await tween.finished
	texture.visible = false
