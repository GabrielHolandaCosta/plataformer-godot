extends Control

const _FONT_PATH = "res://assets/Extras/fonts/RevMiniPixel.ttf"
const MAX_HP     = 3

# Geometria de cada segmento
const _SEG_W   = 26.0
const _SEG_H   = 10.0
const _SEG_GAP = 3.0
const _LABEL_W = 18.0
const _LABEL_G = 5.0

# Paleta
const _C_FILL_3 = Color(0.20, 0.78, 0.28, 1.0)   # verde  — 3 HP
const _C_FILL_2 = Color(0.95, 0.62, 0.08, 1.0)   # laranja — 2 HP
const _C_FILL_1 = Color(0.88, 0.16, 0.16, 1.0)   # vermelho — 1 HP
const _C_EMPTY  = Color(0.09, 0.06, 0.06, 1.0)
const _C_BORDER = Color(0.22, 0.22, 0.28, 1.0)
const _C_SHADOW = Color(0.00, 0.00, 0.00, 0.80)

var _fills:   Array[ColorRect] = []
var _tracked: int = -1
var _pulse_tw: Tween = null
var _font: Font


func _ready() -> void:
	_font = load(_FONT_PATH)

	# posiciona no canto inferior-esquerdo dentro do MarginContainer
	size_flags_horizontal = 0  # alinha à esquerda
	size_flags_vertical   = 8  # alinha em baixo (SIZE_SHRINK_END)

	_build()

	_tracked = Globals.player_life
	_refresh(_tracked, false)


func _process(_delta: float) -> void:
	var life := Globals.player_life
	if life == _tracked:
		return
	var old  := _tracked
	_tracked  = life
	_refresh(life, true)
	if life < old:
		_flash()
		if life == 1:
			_start_pulse()
		else:
			_stop_pulse()


# ── construção ────────────────────────────────────────────────────────────────

func _build() -> void:
	var total_w := _LABEL_W + _LABEL_G + MAX_HP * _SEG_W + (MAX_HP - 1) * _SEG_GAP
	var total_h := _SEG_H + 6.0
	custom_minimum_size = Vector2(total_w, total_h)
	size                = custom_minimum_size

	# Label "HP"
	var lbl := Label.new()
	lbl.text     = "HP"
	lbl.position = Vector2(0, 3)
	lbl.size     = Vector2(_LABEL_W, _SEG_H)
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color",        Color(1, 1, 1, 0.90))
	lbl.add_theme_color_override("font_shadow_color", _C_SHADOW)
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	add_child(lbl)

	for i in MAX_HP:
		var x := _LABEL_W + _LABEL_G + i * (_SEG_W + _SEG_GAP)

		# sombra (profundidade)
		var shadow := ColorRect.new()
		shadow.color    = Color(0, 0, 0, 0.55)
		shadow.position = Vector2(x + 1, 5)
		shadow.size     = Vector2(_SEG_W, _SEG_H)
		add_child(shadow)

		# borda externa
		var border := ColorRect.new()
		border.color    = _C_BORDER
		border.position = Vector2(x, 4)
		border.size     = Vector2(_SEG_W, _SEG_H)
		add_child(border)

		# fundo vazio
		var bg := ColorRect.new()
		bg.color    = _C_EMPTY
		bg.position = Vector2(x + 1, 5)
		bg.size     = Vector2(_SEG_W - 2, _SEG_H - 2)
		add_child(bg)

		# preenchimento animado
		var fill := ColorRect.new()
		fill.color    = _C_FILL_3
		fill.position = Vector2(x + 1, 5)
		fill.size     = Vector2(_SEG_W - 2, _SEG_H - 2)
		add_child(fill)

		# highlight superior (brilho pixel)
		var hl := ColorRect.new()
		hl.color    = Color(1, 1, 1, 0.08)
		hl.position = Vector2(x + 1, 5)
		hl.size     = Vector2(_SEG_W - 2, 1)
		add_child(hl)

		_fills.append(fill)


# ── lógica de atualização ─────────────────────────────────────────────────────

func _refresh(life: int, animated: bool) -> void:
	var color := _color_for(life)
	for i in MAX_HP:
		_fills[i].color = color
		var target_w := (_SEG_W - 2) if i < life else 0.0
		if animated:
			var tw := create_tween()
			tw.tween_property(_fills[i], "size:x", target_w, 0.28) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			_fills[i].size.x = target_w


func _color_for(life: int) -> Color:
	match life:
		1: return _C_FILL_1
		2: return _C_FILL_2
		_: return _C_FILL_3


# ── efeitos ───────────────────────────────────────────────────────────────────

func _flash() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.6, 0.4, 0.4, 1.0), 0.07)
	tw.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.22)


func _start_pulse() -> void:
	if _pulse_tw and _pulse_tw.is_running():
		return
	_pulse_tw = create_tween().set_loops()
	_pulse_tw.tween_property(_fills[0], "modulate", Color(1.0, 0.25, 0.25, 1.0), 0.45)
	_pulse_tw.tween_property(_fills[0], "modulate", Color(1.0, 1.00, 1.00, 1.0), 0.45)


func _stop_pulse() -> void:
	if _pulse_tw:
		_pulse_tw.kill()
		_pulse_tw = null
	if not _fills.is_empty():
		_fills[0].modulate = Color(1, 1, 1, 1)
