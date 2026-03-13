extends Node2D

@onready var player := $player as CharacterBody2D
@onready var camera := $camera as Camera2D
@onready var clock_timer = $HUD/control/clock_timer
@onready var control = $HUD/control

func _ready():
	player.follow_camera(camera)
	player.player_has_died.connect(reload_game)
	control.time_is_up.connect(reload_game)

	Globals.coins = 0
	Globals.score = 0
	Globals.player_life = 3


func _process(delta):
	pass


func reload_game():
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
