extends Area2D
class_name FlyingObelisk

# ----------------------------------------------------------------------------
# Flying Obelisk
# ----------------------------------------------------------------------------
# Aparece após o boss final ser derrotado. O player se aproxima e aperta
# E pra interagir. A interação dispara uma cutscene: o obelisco brilha,
# acelera a rotação, dispara uma explosão branca em tela cheia e a partir
# daí transita pra world_4 (floresta restaurada).
# ----------------------------------------------------------------------------

const TRANSITION_SCENE := preload("res://prefabs/level_transition.tscn")
const RESTORATION_CUTSCENE := preload("res://prefabs/restoration_cutscene.tscn")

@export var next_level: String = "res://levels/world_04.tscn"

@onready var body: Node2D = $body
@onready var obelisk: AnimatedSprite2D = $body/obelisk
@onready var glow_inner: ColorRect = $body/glow_inner
@onready var prompt: Label = $prompt
@onready var subtitle: Label = $subtitle
@onready var interaction: CollisionShape2D = $interaction
@onready var particles: CPUParticles2D = $particles
@onready var aura: CPUParticles2D = $aura
@onready var pulse_circle: TextureRect = $body/pulse

var player_inside: bool = false
var triggered: bool = false
var hover_time: float = 0.0
var spawn_time: float = 0.0
var fade_in_done: bool = false


func _ready() -> void:
	body.modulate.a = 0.0
	prompt.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("flying_obelisk")
	# Spawn animation: rises from 0 alpha, with subtitle text fading in
	_play_spawn_animation()


func _play_spawn_animation() -> void:
	# Sobe um pouco enquanto aparece
	var tw := create_tween().set_parallel(true)
	tw.tween_property(body, "modulate:a", 1.0, 0.9)
	tw.tween_property(body, "position:y", body.position.y - 8.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(subtitle, "modulate:a", 1.0, 1.0).set_delay(0.4)
	await tw.finished
	fade_in_done = true


func _process(delta: float) -> void:
	hover_time += delta
	body.position.y += sin(hover_time * 1.6) * 0.06
	# Acelera a animação do obelisco quando o player ativa
	if triggered and obelisk:
		var t := Time.get_ticks_msec() / 1000.0 - spawn_time
		obelisk.speed_scale = clamp(1.0 + t * 1.5, 1.0, 6.0)
	if pulse_circle:
		var s := 1.0 + sin(hover_time * 3.5) * 0.18
		pulse_circle.scale = Vector2(s, s)
		pulse_circle.modulate.a = 0.45 + sin(hover_time * 3.5) * 0.20

	if player_inside and fade_in_done and not triggered:
		# Mantém prompt visível
		if prompt.modulate.a < 1.0:
			prompt.modulate.a = lerp(prompt.modulate.a, 1.0, delta * 6.0)
	else:
		if prompt.modulate.a > 0.0:
			prompt.modulate.a = lerp(prompt.modulate.a, 0.0, delta * 6.0)


func _unhandled_input(event: InputEvent) -> void:
	if triggered or not player_inside or not fade_in_done:
		return
	# Não dispara se houver um diálogo ativo (evita conflito com a tecla E).
	if get_tree().get_nodes_in_group("dialog").size() > 0:
		return
	if event.is_action_pressed("interact"):
		_trigger_restoration()


func _on_body_entered(b: Node) -> void:
	if b.is_in_group("player"):
		player_inside = true


func _on_body_exited(b: Node) -> void:
	if b.is_in_group("player"):
		player_inside = false


func _trigger_restoration() -> void:
	triggered = true
	spawn_time = Time.get_ticks_msec() / 1000.0
	# Trava o player
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set("can_move", false)
		if p is CharacterBody2D:
			(p as CharacterBody2D).velocity = Vector2.ZERO

	# Esconde prompt
	prompt.modulate.a = 0.0
	subtitle.modulate.a = 0.0

	# Acelera partículas e aumenta o brilho
	if aura:
		aura.amount = 80
		aura.initial_velocity_max *= 2.5
	if particles:
		particles.amount = 60
		particles.initial_velocity_max *= 2.5

	# Faz o obelisco brilhar e crescer
	var tw := create_tween().set_parallel(true)
	tw.tween_property(glow_inner, "modulate:a", 1.0, 0.6)
	tw.tween_property(body, "scale", Vector2(1.4, 1.4), 1.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(obelisk, "modulate", Color(1.5, 1.4, 1.0, 1.0), 1.4)
	await tw.finished

	# Spawn da cutscene de explosão (CanvasLayer overlay)
	var cutscene := RESTORATION_CUTSCENE.instantiate()
	get_tree().current_scene.add_child(cutscene)
	cutscene.start(next_level)
