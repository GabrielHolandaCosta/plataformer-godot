extends Node2D

@onready var player := $player as CharacterBody2D
@onready var player_scene = preload("res://actors/player.tscn")

@onready var camera := $camera as Camera2D
@onready var clock_timer = $HUD/control/clock_timer
@onready var control = $HUD/control

@export var obelisk_spawn_marker_path: NodePath = NodePath("obelisk_marker")
const OBELISK_SCENE := preload("res://prefabs/flying_obelisk.tscn")


func _ready() -> void:
	Globals.player_start_position = $player_start_position
	Globals.player = player
	Globals.spawn_position = player.global_position
	Globals.current_checkpoint = null
	Globals.player.follow_camera(camera)
	Globals.player.player_has_died.connect(game_over)
	control.time_is_up.connect(game_over)

	# Conecta o sinal do boss pra spawnar o obelisco quando ele cair
	var boss := get_node_or_null("enemies/boss/necromancer")
	if boss and boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_boss_defeated)


func reload_game():
	await get_tree().create_timer(1.0).timeout
	var new_player = player_scene.instantiate()
	add_child(new_player)
	control.reset_clock_timer()
	Globals.player = new_player
	Globals.player.follow_camera(camera)
	Globals.player.player_has_died.connect(game_over)
	Globals.coins = 0
	Globals.score = 0
	Globals.player_life = 3
	Globals.respawn_player()


func game_over():
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")


func _on_boss_defeated() -> void:
	# Pequeno atraso pra dar respiro depois do desaparecimento do boss.
	await get_tree().create_timer(0.6).timeout
	if not is_instance_valid(self):
		return

	_show_quest_banner()

	var marker := get_node_or_null(obelisk_spawn_marker_path)
	var spawn_pos: Vector2 = Vector2(0, 0)
	if marker is Node2D:
		spawn_pos = (marker as Node2D).global_position
	else:
		# Fallback: spawna onde o boss morreu (centro da arena)
		spawn_pos = camera.global_position
	var obelisk := OBELISK_SCENE.instantiate()
	add_child(obelisk)
	obelisk.global_position = spawn_pos


func _show_quest_banner() -> void:
	# Mensagem em tela cheia: "Restaure a Floresta, Guardião".
	var banner := Label.new()
	banner.text = "Restaure a Floresta, Guardião"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.modulate = Color(1, 0.95, 0.7, 0)
	banner.add_theme_font_override("font", load("res://assets/Extras/fonts/RevMiniPixel.ttf"))
	banner.add_theme_font_size_override("font_size", 22)
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	banner.add_theme_constant_override("outline_size", 6)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.offset_left = -200.0
	banner.offset_right = 200.0
	banner.offset_top = -16.0
	banner.offset_bottom = 16.0
	var hud := get_node_or_null("HUD")
	if hud:
		hud.add_child(banner)
	else:
		add_child(banner)
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.8)
	tw.tween_interval(2.6)
	tw.tween_property(banner, "modulate:a", 0.0, 0.8)
	tw.tween_callback(banner.queue_free)
