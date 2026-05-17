extends CanvasLayer
class_name RestorationCutscene

# ----------------------------------------------------------------------------
# Cutscene de Restauração
# ----------------------------------------------------------------------------
# Tocada quando o player interage com o FlyingObelisk após derrotar o boss.
# Sequência:
#   1) Pequeno shake na tela e fade para amarelo (~0.5s)
#   2) Onda de explosão expande do centro (~0.6s)
#   3) Tela branca pura (~0.7s) - "energia atinge seu pico"
#   4) Carrega world_4 e segura branco mais um instante
#   5) Fade-out branco revela a floresta restaurada
# ----------------------------------------------------------------------------

@onready var sky_rect: ColorRect = $sky
@onready var flash_rect: ColorRect = $flash
@onready var shockwave: TextureRect = $shockwave
@onready var title_label: Label = $title

var _busy: bool = false
var _next_scene: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sky_rect.modulate.a = 0.0
	flash_rect.modulate.a = 0.0
	shockwave.modulate.a = 0.0
	shockwave.scale = Vector2(0.05, 0.05)
	title_label.modulate.a = 0.0


func start(next_scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	_next_scene = next_scene_path

	get_tree().paused = true

	# Fase 1 — fade amarelo + título sobe (com shake leve)
	var tw1 := create_tween().set_parallel(true)
	tw1.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw1.tween_property(sky_rect, "modulate:a", 0.6, 0.45).set_trans(Tween.TRANS_SINE)
	tw1.tween_property(title_label, "modulate:a", 1.0, 0.55)
	await tw1.finished

	# Fase 2 — onda de explosão expande
	var tw2 := create_tween().set_parallel(true)
	tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(shockwave, "modulate:a", 1.0, 0.15)
	tw2.tween_property(shockwave, "scale", Vector2(8.0, 8.0), 0.55).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw2.tween_property(sky_rect, "modulate:a", 1.0, 0.4).set_delay(0.1)
	await tw2.finished

	# Fase 3 — flash branco puro
	var tw3 := create_tween().set_parallel(true)
	tw3.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw3.tween_property(flash_rect, "modulate:a", 1.0, 0.25)
	tw3.tween_property(shockwave, "modulate:a", 0.0, 0.25)
	await tw3.finished

	# Hold no branco
	await get_tree().create_timer(0.7, true, false, true).timeout

	# Fase 4 — sobrevive à troca de cena
	var tree := get_tree()
	var p := get_parent()
	if p:
		p.remove_child(self)
	tree.root.add_child(self)

	var err := tree.change_scene_to_file(_next_scene)
	if err != OK:
		push_error("Falha ao trocar de cena: %s" % _next_scene)
		tree.paused = false
		queue_free()
		return

	await tree.process_frame
	await tree.process_frame
	tree.paused = false

	# Fase 5 — fade-out do branco / amarelo, revela a nova floresta
	var tw4 := create_tween().set_parallel(true)
	tw4.tween_property(title_label, "modulate:a", 0.0, 0.5)
	tw4.tween_property(flash_rect, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_delay(0.4)
	tw4.tween_property(sky_rect, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE).set_delay(0.4)
	await tw4.finished
	queue_free()
