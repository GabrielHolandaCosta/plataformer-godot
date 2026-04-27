extends Control

@onready var coins_counter = $container/coins_container/coins_counter as Label
@onready var timer_counter = $container/timer_container/timer_counter as Label
@onready var score_counter = $container/score_container/score_counter as Label
@onready var clock_timer   = $clock_timer as Timer

var minutes = 0
var seconds = 0

@export_range(0, 5) var default_minutes := 1
@export_range(0, 59) var default_seconds := 0

signal time_is_up()


func _ready():
	coins_counter.text = str("%04d" % Globals.coins)
	score_counter.text = str("%06d" % Globals.score)

	reset_clock_timer()
	update_timer_text()
	clock_timer.start()

	# Adiciona a barra de vida animada no mesmo lugar (canto inferior-esquerdo)
	var health_bar = preload("res://prefabs/health_bar.tscn").instantiate()
	$container.add_child(health_bar)


func _process(_delta):
	coins_counter.text = str("%04d" % Globals.coins)
	score_counter.text = str("%06d" % Globals.score)


func _on_clock_timer_timeout():
	if seconds == 0:
		if minutes == 0:
			clock_timer.stop()
			emit_signal("time_is_up")
			return
		else:
			minutes -= 1
			seconds = 59
	else:
		seconds -= 1

	update_timer_text()


func reset_clock_timer():
	minutes = default_minutes
	seconds = default_seconds


func update_timer_text():
	timer_counter.text = str("%02d" % minutes) + ":" + str("%02d" % seconds)
