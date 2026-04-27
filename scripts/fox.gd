extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $anim
@onready var interaction_area: Area2D = $area_sign
@onready var texture: CanvasItem = $texture

var player_inside := false

# controle da animação
var float_time := 0.0


func _ready():
	sprite.play("idle")

	# começa invisível
	texture.visible = false
	texture.modulate.a = 0.0

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(delta):
	if player:
		sprite.flip_h = player.global_position.x < global_position.x

	# animação só quando visível
	if texture.visible:
		float_time += delta

		# 🎮 subir e descer
		texture.position.y = -20 + sin(float_time * 2.0) * 4.0

		# ✨ pulsar
		var scale = 1.0 + sin(float_time * 3.0) * 0.08
		texture.scale = Vector2(scale, scale)


func _unhandled_input(event):
	if not player_inside:
		return

	# impede abrir outro diálogo
	if get_tree().get_nodes_in_group("dialog").size() > 0:
		return

	if Input.is_action_just_pressed("interact"):
		start_dialog()


func start_dialog():
	hide_texture()
	
	player.can_move = false

	var dialog_scene = preload("res://prefabs/dialog_screen.tscn")
	var dialog = dialog_scene.instantiate()

	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.add_child(dialog)
	else:
		get_tree().root.add_child(dialog)

	dialog.start({
		0: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "…Você também sentiu isso, não foi?",
			"title": "Raposa"
		},
		1: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "O ar está estranho. Como se a floresta estivesse tentando avisar algo.",
			"title": "Raposa"
		},
		2: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "Até que enfim você acordou, Guardião… eu já não sabia mais a quem recorrer.",
			"title": "Raposa"
		},
		3: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "As árvores adoecem... e o fogo se espalha rápido demais.",
			"title": "Raposa"
		},
		4: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "Mas isso não é só destruição… tem algo por trás disso.",
			"title": "Raposa"
		},
		5: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "Eu senti uma presença… me observando… mesmo quando não havia ninguém.",
			"title": "Raposa"
		},
		6: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "Os animais estão fugindo… e os espíritos… eles estão em silêncio.",
			"title": "Raposa"
		},
		7: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "Eu tentei seguir os sinais, mas tudo parecia errado.",
			"title": "Raposa"
		},
		8: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "Não sei o que está causando isso… e isso é o que mais me assusta.",
			"title": "Raposa"
		},
		9: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "Mas existe algo no coração da floresta… algo que ainda resiste.",
			"title": "Raposa"
		},
		10: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "Se há respostas… elas estão lá.",
			"title": "Raposa"
		},
		11: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "Vá, Guardião! Descubra a verdade antes que seja tarde.",
			"title": "Raposa"
		},
		12: {
			"faceset": "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png",
			"dialog": "…Porque seja lá o que for… já sabe que você acordou.",
			"title": "Raposa"
		}
	})


# ===== TEXTURE CONTROL =====

func show_texture():
	texture.visible = true

	# 💡 fade in
	var tween = create_tween()
	tween.tween_property(texture, "modulate:a", 1.0, 0.25)


func hide_texture():
	var tween = create_tween()
	tween.tween_property(texture, "modulate:a", 0.0, 0.2)
	await tween.finished
	texture.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true

		if get_tree().get_nodes_in_group("dialog").size() == 0:
			show_texture()


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		hide_texture()
