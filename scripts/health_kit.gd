extends Area2D
class_name HealthKit

# ----------------------------------------------------------------------------
# Health Kit
# ----------------------------------------------------------------------------
# Item que sai animado de um baú (ou pode ser colocado direto no mapa).
# Ao tocar o player, restaura a vida ao máximo (3) e some com efeito.
# ----------------------------------------------------------------------------

@export var max_life: int = 3
@export var bob_height: float = 2.5
@export var bob_speed: float = 3.5
@export var spawn_jump_height: float = 22.0
@export var spawn_jump_horizontal: float = 0.0
@export var spawn_jump_duration: float = 0.55

@onready var sprite: Sprite2D = $sprite
@onready var collision: CollisionShape2D = $collision

var collected: bool = false
var ready_to_collect: bool = false
var time_passed: float = 0.0
var base_position: Vector2


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# A coleta só fica disponível após terminar a animação de spawn.
	collision.set_deferred("disabled", true)
	# Pequeno fade-in
	modulate.a = 0.0
	var fade_tw := create_tween()
	fade_tw.tween_property(self, "modulate:a", 1.0, 0.18)


func play_spawn_animation(start_global_position: Vector2, horizontal_dir: float = 0.0) -> void:
	# Posiciona no ponto inicial e faz um pequeno "salto" em arco.
	global_position = start_global_position
	var landing_offset := Vector2(spawn_jump_horizontal * horizontal_dir, 0.0)
	var landing_pos := start_global_position + landing_offset
	base_position = landing_pos

	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD)

	# arco vertical (sobe rápido, desce no final)
	var apex := start_global_position + Vector2(landing_offset.x * 0.5, -spawn_jump_height)
	tw.tween_property(self, "global_position", apex, spawn_jump_duration * 0.45) \
		.set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(self, "global_position", landing_pos, spawn_jump_duration * 0.55) \
		.set_ease(Tween.EASE_IN)

	# pequeno spin durante o voo
	tw.tween_property(sprite, "rotation", deg_to_rad(360.0) * sign(horizontal_dir if horizontal_dir != 0.0 else 1.0), spawn_jump_duration)
	tw.chain().tween_callback(_on_spawn_finished)


func _on_spawn_finished() -> void:
	sprite.rotation = 0.0
	base_position = global_position
	ready_to_collect = true
	collision.set_deferred("disabled", false)


func _process(delta: float) -> void:
	if collected:
		return
	if not ready_to_collect:
		return
	time_passed += delta
	var bob := sin(time_passed * bob_speed) * bob_height
	global_position = Vector2(base_position.x, base_position.y + bob)


func _on_body_entered(body: Node) -> void:
	if collected or not ready_to_collect:
		return
	if not body.is_in_group("player"):
		return
	collect()


func collect() -> void:
	collected = true
	collision.set_deferred("disabled", true)
	# Cura total: vida volta ao máximo (sem ultrapassar).
	if Globals.player_life < max_life:
		Globals.player_life = max_life

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.18) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.22)
	tw.tween_property(self, "position:y", position.y - 12.0, 0.22)
	await tw.finished
	queue_free()
