extends Control

# ----------------------------------------------------------------------------
# Tela de Game Over
# ----------------------------------------------------------------------------
# Conceito: o herói tombou, a floresta silenciou. A tela tem cinzas caindo
# (queimadas pelo Sombra Cinzenta), folhas verdes (memória da floresta viva)
# e silhuetas de árvores ao fundo. Tudo entra animado: vinheta → árvores →
# título com elastic pop → subtítulo → botões deslizando de baixo.
# ----------------------------------------------------------------------------

const TITLE_SCENE := "res://scenes/title_screen.tscn"

@onready var bg: ColorRect = $bg
@onready var vignette: ColorRect = $vignette
@onready var tree_left: TextureRect = $trees/tree_left
@onready var tree_right: TextureRect = $trees/tree_right
@onready var tree_back: TextureRect = $trees/tree_back
@onready var ground_line: ColorRect = $ground_line
@onready var fallen_hero: TextureRect = $fallen_hero
@onready var title: Label = $center/title
@onready var divider: ColorRect = $center/divider
@onready var subtitle: Label = $center/subtitle
@onready var button_box: HBoxContainer = $buttons
@onready var btn_retry: Button = $buttons/btn_retry
@onready var btn_quit: Button = $buttons/btn_quit
@onready var hint: Label = $hint
@onready var ashes: CPUParticles2D = $particles/ashes
@onready var leaves: CPUParticles2D = $particles/leaves
@onready var ember_glow: TextureRect = $center/ember_glow

var _buttons_target_y: float = 0.0
var _entering: bool = true


func _ready() -> void:
	# Estado inicial — tudo invisível, vai entrar animado
	bg.modulate.a = 0.0
	vignette.modulate.a = 0.0
	tree_left.modulate.a = 0.0
	tree_right.modulate.a = 0.0
	tree_back.modulate.a = 0.0
	ground_line.modulate.a = 0.0
	fallen_hero.modulate.a = 0.0
	title.modulate.a = 0.0
	title.scale = Vector2(0.55, 0.55)
	divider.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	button_box.modulate.a = 0.0
	hint.modulate.a = 0.0
	ember_glow.modulate.a = 0.0

	_buttons_target_y = button_box.position.y
	button_box.position.y = _buttons_target_y + 32.0

	# Partículas começam emitindo de cara mas com modulate baixo, sobem com o
	# mesmo tween dos backgrounds.
	ashes.modulate.a = 0.0
	leaves.modulate.a = 0.0
	ashes.emitting = true
	leaves.emitting = true

	await get_tree().process_frame
	_animate_in()
	btn_retry.grab_focus()


func _animate_in() -> void:
	# Fase 1 — escurece o fundo e revela árvores
	var tw1 := create_tween().set_parallel(true)
	tw1.tween_property(bg, "modulate:a", 1.0, 0.55)
	tw1.tween_property(vignette, "modulate:a", 1.0, 0.85).set_delay(0.05)
	tw1.tween_property(tree_back, "modulate:a", 1.0, 0.9).set_delay(0.15)
	tw1.tween_property(tree_left, "modulate:a", 1.0, 0.95).set_delay(0.25)
	tw1.tween_property(tree_right, "modulate:a", 1.0, 0.95).set_delay(0.35)
	tw1.tween_property(ground_line, "modulate:a", 0.55, 0.8).set_delay(0.4)
	tw1.tween_property(ashes, "modulate:a", 1.0, 1.0).set_delay(0.5)
	tw1.tween_property(leaves, "modulate:a", 0.85, 1.0).set_delay(0.7)
	tw1.tween_property(fallen_hero, "modulate:a", 1.0, 0.7).set_delay(0.7)

	# Fase 2 — título com pop elastic + brilho
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(ember_glow, "modulate:a", 0.65, 0.6).set_delay(0.7)
	tw2.tween_property(title, "modulate:a", 1.0, 0.55).set_delay(0.8)
	tw2.tween_property(title, "scale", Vector2.ONE, 0.85).set_delay(0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Fase 3 — divider + subtítulo
	var tw3 := create_tween().set_parallel(true)
	tw3.tween_property(divider, "modulate:a", 1.0, 0.45).set_delay(1.35)
	tw3.tween_property(subtitle, "modulate:a", 1.0, 0.55).set_delay(1.45)

	# Fase 4 — botões deslizam de baixo
	var tw4 := create_tween().set_parallel(true)
	tw4.tween_property(button_box, "modulate:a", 1.0, 0.4).set_delay(1.7)
	tw4.tween_property(button_box, "position:y", _buttons_target_y, 0.6).set_delay(1.7).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw4.tween_property(hint, "modulate:a", 0.65, 0.5).set_delay(2.0)
	tw4.tween_callback(_on_animate_in_done).set_delay(2.4)


func _on_animate_in_done() -> void:
	_entering = false
	_start_title_pulse()
	_start_glow_pulse()


func _start_title_pulse() -> void:
	# Pulsação sutil constante no título — vivo, respirando
	var tw := create_tween().set_loops()
	tw.tween_property(title, "scale", Vector2(1.025, 1.025), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(title, "scale", Vector2(1.0, 1.0), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _start_glow_pulse() -> void:
	# Brilho atrás do título oscila como uma brasa
	var tw := create_tween().set_loops()
	tw.tween_property(ember_glow, "modulate:a", 0.85, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(ember_glow, "modulate:a", 0.45, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ----------------------------------------------------------------------------
# Inputs / botões
# ----------------------------------------------------------------------------

func _on_retry_pressed() -> void:
	_go_to_title()


func _on_quit_pressed() -> void:
	_quit_game()


func _on_btn_focus_entered(btn: Button) -> void:
	# Pequeno destaque visual quando o botão recebe foco — o stylebox de hover
	# já cuida do visual, mas a gente faz um leve scale up pra dar peso.
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_btn_focus_exited(btn: Button) -> void:
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if _entering:
		return
	if event.is_action_pressed("ui_cancel"):
		_quit_game()


func _go_to_title() -> void:
	# Reseta progresso pra próxima run não carregar bosses já derrotados.
	Globals.bosses_defeated = {}
	Globals.coins = 0
	Globals.score = 0
	Globals.player_life = 3
	get_tree().change_scene_to_file(TITLE_SCENE)


func _quit_game() -> void:
	get_tree().quit()
