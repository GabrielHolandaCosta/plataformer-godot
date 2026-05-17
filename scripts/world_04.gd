extends Node2D

# ----------------------------------------------------------------------------
# world_04 — Floresta Restaurada (Final)
# ----------------------------------------------------------------------------
# Cutscene de encerramento. O player fica imóvel; a Raposa anda até ele,
# fala um diálogo final e o jogo transita pra cena de créditos.
# ----------------------------------------------------------------------------

const DIALOG_SCENE := preload("res://prefabs/dialog_screen.tscn")
const CREDITS_SCENE := "res://scenes/credits.tscn"
const FONT_PATH := "res://assets/Extras/fonts/RevMiniPixel.ttf"

const FACESET_FOX := "res://assets/amazon/fox sprites 2d pixel/faceset_fox.png"
const FACESET_HERO := "res://assets/hero/faceset/faceset.png"

@export var fox_path: NodePath = NodePath("NPCs/fox")
@export var fox_anim_path: NodePath = NodePath("NPCs/fox/anim")
@export var fox_walk_target_path: NodePath = NodePath("fox_walk_target")

@onready var player := $player as CharacterBody2D
@onready var camera := $camera as Camera2D
@onready var fox: Node2D = get_node_or_null(fox_path) as Node2D
@onready var fox_anim: AnimatedSprite2D = get_node_or_null(fox_anim_path) as AnimatedSprite2D
@onready var fox_walk_target: Marker2D = get_node_or_null(fox_walk_target_path) as Marker2D

var fox_walk_speed: float = 65.0
var dialog_active: bool = false
var sequence_started: bool = false
var credits_started: bool = false


func _ready() -> void:
	Globals.player = player
	# Câmera teleporta pra cima do player imediatamente, sem suavizar — o
	# spawn padrão da câmera fica longe do player e o smoothing fazia
	# "voar" pelo céu vazio durante a chegada da cutscene.
	camera.global_position = player.global_position
	camera.reset_smoothing()
	Globals.player.follow_camera(camera)
	# Player imóvel desde o spawn — ainda em cutscene
	player.can_move = false
	if player is CharacterBody2D:
		player.velocity = Vector2.ZERO

	# Pequeno delay pra cena assentar (e o fade-in da cutscene anterior terminar)
	await get_tree().create_timer(1.4).timeout
	_start_sequence()


func _process(delta: float) -> void:
	if not sequence_started or dialog_active or credits_started:
		return
	# Faz a raposa andar até o player
	if not is_instance_valid(fox_walk_target) or not is_instance_valid(fox):
		return
	var target_x: float = fox_walk_target.global_position.x
	var dist_x: float = target_x - fox.global_position.x
	if abs(dist_x) > 4.0:
		var step: float = sign(dist_x) * fox_walk_speed * delta
		fox.global_position.x += step
		if fox_anim:
			fox_anim.flip_h = step < 0.0
			_play_fox_anim("run")
	else:
		# Chegou perto. Para e dispara o diálogo final.
		_play_fox_anim("idle")
		if not dialog_active:
			_start_final_dialog()


func _play_fox_anim(name: String) -> void:
	# Fallback pra "idle" se a animação solicitada não existir (a fox.tscn
	# original só tem idle).
	if fox_anim == null:
		return
	var sf: SpriteFrames = fox_anim.sprite_frames
	var target := name
	if sf == null or not sf.has_animation(target):
		target = "idle"
	if fox_anim.animation != target:
		fox_anim.play(target)


func _start_sequence() -> void:
	sequence_started = true
	_play_fox_anim("run")


func _start_final_dialog() -> void:
	if credits_started:
		return
	dialog_active = true
	var lines := [
		{"title": "Raposa", "faceset": FACESET_FOX,  "dialog": "Você… conseguiu! Eu senti tudo no exato momento — a floresta inteira se sacudiu e respirou de novo!"},
		{"title": "Raposa", "faceset": FACESET_FOX,  "dialog": "Onde havia cinzas, agora há broto. Onde havia silêncio, agora há canto."},
		{"title": "Guardião", "faceset": FACESET_HERO, "dialog": "Não foi só eu… ela queria viver. Eu apenas dei o último empurrão."},
		{"title": "Raposa", "faceset": FACESET_FOX,  "dialog": "Não. Foi você. A Sombra Cinzenta era um peso que essa terra carregava há séculos."},
		{"title": "Raposa", "faceset": FACESET_FOX,  "dialog": "E você libertou cada raiz, cada ninho, cada riacho que ainda ousava sonhar com a primavera."},
		{"title": "Guardião", "faceset": FACESET_HERO, "dialog": "Foi… mágico. De verdade."},
		{"title": "Raposa", "faceset": FACESET_FOX,  "dialog": "Em nome de toda criatura que volta agora pra casa: obrigado, Guardião. Obrigado por escutar a floresta quando ninguém mais escutava."},
		{"title": "Raposa", "faceset": FACESET_FOX,  "dialog": "Descanse. A floresta vai cuidar de você por um bom tempo, agora."},
	]
	var data := {}
	for i in lines.size():
		data[i] = lines[i]

	var dialog := DIALOG_SCENE.instantiate()
	var hud := get_node_or_null("HUD")
	if hud:
		hud.add_child(dialog)
	else:
		get_tree().root.add_child(dialog)
	# O dialog_screen.gd remove o lock do player automaticamente quando termina,
	# mas aqui queremos manter ele preso e ir direto pros créditos.
	dialog.start(data)
	dialog.tree_exited.connect(_on_final_dialog_finished)


func _on_final_dialog_finished() -> void:
	if credits_started:
		return
	credits_started = true
	sequence_started = false
	dialog_active = true
	# Player permanece travado — vai pra créditos
	if player:
		player.set("can_move", false)
		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(1.2).timeout
	if not is_instance_valid(self):
		return
	await _play_credits_transition()
	if not is_instance_valid(self):
		return
	tree = get_tree()
	if tree == null:
		return
	tree.change_scene_to_file(CREDITS_SCENE)


func _play_credits_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)

	var fade := ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.08, 0.18, 0.11, 0.0)
	layer.add_child(fade)

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.85, 1.0, 0.62, 0.0)
	layer.add_child(glow)

	var label := Label.new()
	label.text = "A floresta foi restaurada. Obrigado, Guardiao!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1, 0.96, 0.72, 0)
	label.add_theme_font_override("font", load(FONT_PATH))
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.02, 1))
	label.add_theme_constant_override("outline_size", 7)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -260.0
	label.offset_right = 260.0
	label.offset_top = -20.0
	label.offset_bottom = 20.0
	layer.add_child(label)

	var tree := get_tree()
	if tree == null:
		return
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.92, 0.7)
	tw.parallel().tween_property(glow, "color:a", 0.22, 0.55)
	tw.parallel().tween_property(label, "modulate:a", 1.0, 0.55)
	tw.tween_interval(0.85)
	tw.tween_property(glow, "color:a", 0.7, 0.35)
	tw.parallel().tween_property(label, "position:y", label.position.y - 14.0, 0.35)
	tw.tween_property(fade, "color", Color(0.015, 0.018, 0.028, 1.0), 0.45)
	await tw.finished
