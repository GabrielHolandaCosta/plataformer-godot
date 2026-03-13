extends CharacterBody2D

const BOX_PIECES_SCENE: PackedScene = preload("res://prefabs/box_pieces.tscn")
const COIN_SCENE: PackedScene = preload("res://prefabs/coin_rigid.tscn")

@onready var animation_player: AnimationPlayer = $anim
@onready var spawn_coin: Marker2D = $spawn_coin

@export var pieces: PackedStringArray
@export var hitpoints: int = 1
@export var horizontal_impulse: int = 200
@export var vertical_impulse_min: int = -400
@export var vertical_impulse_max: int = -200
@export var drop_coin: bool = true
@export_range(0.0, 1.0) var coin_drop_chance: float = 1.0
@export var coin_impulse_x_min: int = -50
@export var coin_impulse_x_max: int = 50
@export var coin_impulse_y: int = -150

var is_broken: bool = false


func take_hit(damage: int = 1) -> void:
	if is_broken:
		return

	hitpoints -= damage

	if hitpoints <= 0:
		break_sprite()
		return

	_play_hit_animation()


func break_sprite() -> void:
	if is_broken:
		return

	is_broken = true
	_disable_collision()

	if animation_player and animation_player.has_animation("break"):
		animation_player.play("break")
		await animation_player.animation_finished

	_spawn_pieces()
	_try_spawn_coin()
	queue_free()


func _play_hit_animation() -> void:
	if animation_player and animation_player.has_animation("hit"):
		animation_player.play("hit")


func _spawn_pieces() -> void:
	for i in range(pieces.size()):
		var piece_instance := BOX_PIECES_SCENE.instantiate()
		get_parent().add_child(piece_instance)
		piece_instance.global_position = global_position

		var texture_node := piece_instance.get_node_or_null("texture")
		if texture_node == null:
			continue

		var piece_texture := load(pieces[i])
		if piece_texture == null:
			continue

		texture_node.texture = piece_texture

		if piece_instance.has_method("apply_impulse"):
			piece_instance.apply_impulse(
				Vector2(
					randi_range(-horizontal_impulse, horizontal_impulse),
					randi_range(vertical_impulse_min, vertical_impulse_max)
				)
			)


func _try_spawn_coin() -> void:
	if not drop_coin:
		return

	if randf() > coin_drop_chance:
		return

	create_coin()


func create_coin() -> void:
	if spawn_coin == null:
		return

	var coin := COIN_SCENE.instantiate()
	get_parent().call_deferred("add_child", coin)
	coin.global_position = spawn_coin.global_position

	if coin.has_method("apply_impulse"):
		coin.apply_impulse(
			Vector2(
				randi_range(coin_impulse_x_min, coin_impulse_x_max),
				coin_impulse_y
			)
		)


func _disable_collision() -> void:
	var collision := get_node_or_null("collision")
	if collision:
		collision.set_deferred("disabled", true)
