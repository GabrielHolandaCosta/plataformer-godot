extends Area2D

const TRANSITION_SCENE := preload("res://prefabs/level_transition.tscn")

@export var next_level: String = ""
# Id do boss que precisa estar derrotado para o goal funcionar.
# Vazio = sempre destravado (igual antigamente).
@export var requires_boss: String = ""
# Texto que aparece na tela de transição quando o player passa.
@export var transition_title: String = ""
@export var transition_subtitle: String = ""
# Texto exibido acima do goal quando ainda está trancado.
@export var locked_message: String = "Trancado"

@onready var lock_label: Label = get_node_or_null("lock_label")
@onready var unlock_glow: Node2D = get_node_or_null("unlock_glow")
@onready var unlock_particles: CPUParticles2D = get_node_or_null("unlock_particles")

var is_switching: bool = false
var unlocked: bool = true
var _was_unlocked: bool = false


func _ready() -> void:
	if lock_label:
		lock_label.text = locked_message
	unlocked = _compute_unlocked()
	_was_unlocked = unlocked
	_apply_lock_visual(false)


func _process(_delta: float) -> void:
	var should_unlock := _compute_unlocked()
	if should_unlock and not unlocked:
		unlocked = true
		_apply_lock_visual(true)
	elif not should_unlock and unlocked:
		unlocked = false
		_apply_lock_visual(false)


func _compute_unlocked() -> bool:
	if requires_boss == "":
		return true
	return Globals.is_boss_defeated(requires_boss)


func _apply_lock_visual(animated: bool) -> void:
	if lock_label:
		lock_label.visible = not unlocked
	if unlock_glow:
		unlock_glow.visible = unlocked
		if unlocked and animated:
			unlock_glow.modulate.a = 0.0
			unlock_glow.scale = Vector2(0.6, 0.6)
			var tw := create_tween().set_parallel(true)
			tw.tween_property(unlock_glow, "modulate:a", 1.0, 0.45)
			tw.tween_property(unlock_glow, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		elif unlocked:
			unlock_glow.modulate.a = 1.0
			unlock_glow.scale = Vector2.ONE
	if unlock_particles:
		unlock_particles.emitting = unlocked


func _on_body_entered(body: Node) -> void:
	if is_switching:
		return
	if not body.is_in_group("player"):
		return
	if not unlocked:
		# bloqueado: poderia tocar SFX ou piscar o lock_label aqui
		_pulse_lock_label()
		return
	if next_level == "":
		print("No Scene Loaded")
		return

	is_switching = true
	# Trava o player pra não mexer durante a transição.
	if body.has_method("set"):
		body.set("can_move", false)
		body.set("velocity", Vector2.ZERO)

	var trans = TRANSITION_SCENE.instantiate()
	get_tree().current_scene.add_child(trans)
	trans.start_transition(next_level, transition_title, transition_subtitle)


func _pulse_lock_label() -> void:
	if lock_label == null or not lock_label.visible:
		return
	var tw := create_tween()
	tw.tween_property(lock_label, "modulate", Color(1, 0.5, 0.5, 1), 0.12)
	tw.tween_property(lock_label, "modulate", Color(1, 1, 1, 1), 0.18)
