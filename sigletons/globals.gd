extends Node

var coins := 0
var score := 0
var player_life := 3

var player_start_position

var player = null

var current_checkpoint = null
var spawn_position: Vector2 = Vector2.ZERO
var respawn_offset: Vector2 = Vector2(0, -4)

func respawn_player():
	if player == null:
		return

	if current_checkpoint != null:
		player.global_position = current_checkpoint.global_position + respawn_offset
	else:
		if spawn_position != Vector2.ZERO:
			player.global_position = spawn_position + respawn_offset
		else:
			player.global_position = player_start_position.global_position

	if player.has_method("set"):
		player.set("velocity", Vector2.ZERO)
