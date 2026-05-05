extends CanvasLayer
class_name LevelTransition

# Transição cinematográfica entre níveis.
# Sequência:
#   1. Fade-out da tela (preto vinheta)  ~0.55s
#   2. Título do próximo capítulo aparece com pop-in (escala + alfa) ~0.6s
#   3. Subtítulo desliza por baixo (alfa + leve subida) ~0.45s
#   4. Pausa ~1.0s
#   5. Reparenta no root, troca de cena, e dá fade-in suave
#
# A camada do CanvasLayer fica em 100 pra ficar acima de qualquer HUD.

@onready var fade_rect: ColorRect = $fade_rect
@onready var vignette: TextureRect = $vignette
@onready var title_label: Label = $title
@onready var subtitle_label: Label = $subtitle
@onready var divider: ColorRect = $divider

var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade_rect.modulate.a = 0.0
	vignette.modulate.a = 0.0
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.85, 0.85)
	subtitle_label.modulate.a = 0.0
	subtitle_label.position.y = subtitle_label.position.y + 8
	divider.modulate.a = 0.0


func start_transition(next_scene_path: String, title_text: String = "", subtitle_text: String = "") -> void:
	if _busy:
		return
	_busy = true

	# Pausa o jogo enquanto a transição roda — parece mais limpo.
	get_tree().paused = true

	title_label.text = title_text
	subtitle_label.text = subtitle_text
	var subtitle_target_y := subtitle_label.position.y - 8

	# Fase 1 — escurece
	var tw1 := create_tween().set_parallel(true)
	tw1.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw1.tween_property(fade_rect, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	tw1.tween_property(vignette, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	await tw1.finished

	# Fase 2 — título aparece com pop-in
	if title_text != "":
		var tw2 := create_tween().set_parallel(true)
		tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw2.tween_property(title_label, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
		tw2.tween_property(title_label, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw2.tween_property(divider, "modulate:a", 1.0, 0.4).set_delay(0.15)
		await tw2.finished

	# Fase 3 — subtítulo desliza pra cima e aparece
	if subtitle_text != "":
		var tw3 := create_tween().set_parallel(true)
		tw3.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw3.tween_property(subtitle_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
		tw3.tween_property(subtitle_label, "position:y", subtitle_target_y, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		await tw3.finished

	# Fase 4 — segura o título por um instante pra dar peso
	var hold_timer := get_tree().create_timer(1.0, true, false, true)
	await hold_timer.timeout

	# Fase 5 — sobrevive à troca de cena e faz fade-in
	var tree := get_tree()
	var p := get_parent()
	if p:
		p.remove_child(self)
	tree.root.add_child(self)

	var err := tree.change_scene_to_file(next_scene_path)
	if err != OK:
		push_error("Falha ao trocar de cena: %s" % next_scene_path)
		tree.paused = false
		queue_free()
		return

	# Espera a nova cena estar disponível.
	await tree.process_frame
	await tree.process_frame

	tree.paused = false

	var tw4 := create_tween().set_parallel(true)
	tw4.tween_property(title_label, "modulate:a", 0.0, 0.45)
	tw4.tween_property(subtitle_label, "modulate:a", 0.0, 0.45)
	tw4.tween_property(divider, "modulate:a", 0.0, 0.4)
	tw4.tween_property(fade_rect, "modulate:a", 0.0, 0.7).set_delay(0.2).set_trans(Tween.TRANS_SINE)
	tw4.tween_property(vignette, "modulate:a", 0.0, 0.55).set_delay(0.25).set_trans(Tween.TRANS_SINE)
	await tw4.finished
	queue_free()
