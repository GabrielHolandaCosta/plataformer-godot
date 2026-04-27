extends Node2D
class_name TreasureChest

# ----------------------------------------------------------------------------
# Treasure Chest
# ----------------------------------------------------------------------------
# Quando o player se aproxima, mostra um ícone de interação (E).
# Ao apertar E, o baú abre com animação e cospe um Health_Kit que cura o
# player até o máximo de vida (3).
# ----------------------------------------------------------------------------

const HEALTH_KIT_SCENE := preload("res://prefabs/health_kit.tscn")

@onready var anim: AnimatedSprite2D = $anim
@onready var area: Area2D = $area
@onready var prompt: Sprite2D = $prompt
@onready var kit_spawn: Marker2D = $kit_spawn

@export var flip_h: bool = false

var player_inside: bool = false
var opened: bool = false
var prompt_time: float = 0.0


func _ready() -> void:
	add_to_group("treasure_chest")
	anim.flip_h = flip_h
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	if anim.sprite_frames and anim.sprite_frames.has_animation("closed"):
		anim.play("closed")
	prompt.visible = false
	prompt.modulate.a = 0.0


func _process(delta: float) -> void:
	if prompt.visible and not opened:
		prompt_time += delta
		# leve flutuação para chamar atenção
		prompt.position.y = -32.0 + sin(prompt_time * 4.0) * 1.5


func _unhandled_input(event: InputEvent) -> void:
	if opened or not player_inside:
		return
	if event.is_action_pressed("interact"):
		_open_chest()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = true
	if not opened:
		_show_prompt()


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = false
	_hide_prompt()


func _show_prompt() -> void:
	prompt.visible = true
	prompt_time = 0.0
	var tw := create_tween()
	tw.tween_property(prompt, "modulate:a", 1.0, 0.18)


func _hide_prompt() -> void:
	if not prompt.visible:
		return
	var tw := create_tween()
	tw.tween_property(prompt, "modulate:a", 0.0, 0.15)
	await tw.finished
	prompt.visible = false


func _open_chest() -> void:
	opened = true
	_hide_prompt()
	if anim.sprite_frames and anim.sprite_frames.has_animation("opening"):
		anim.play("opening")
		await anim.animation_finished
	if anim.sprite_frames and anim.sprite_frames.has_animation("open"):
		anim.play("open")
	_spawn_health_kit()


func _spawn_health_kit() -> void:
	var kit := HEALTH_KIT_SCENE.instantiate()
	get_parent().add_child(kit)
	var spawn_pos: Vector2 = kit_spawn.global_position
	# Direção do "pulo" do kit baseada na posição do player (sai para o lado dele).
	var horizontal_dir := 0.0
	var p := get_tree().get_first_node_in_group("player")
	if p:
		horizontal_dir = sign((p as Node2D).global_position.x - global_position.x)
	if horizontal_dir == 0.0:
		horizontal_dir = 1.0
	kit.call_deferred("play_spawn_animation", spawn_pos, horizontal_dir)
