extends EnemyBase

@onready var spawn_enemy: Marker2D = $"../spawn_enemy"


func _ready() -> void:
	super._ready()
	spawn_instance = preload("res://actors/chery.tscn")
	spawn_instance_position = spawn_enemy
	can_spawn = true
