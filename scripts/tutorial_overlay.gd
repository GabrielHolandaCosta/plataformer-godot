extends Control

const _FONT_PATH = "res://assets/Extras/fonts/RevMiniPixel.ttf"

const _W        = 182.0
const _H        = 102.0
const _MARGIN_L = 10.0

const _C_BG     = Color(0.04, 0.05, 0.10, 0.92)
const _C_BORDER = Color(0.35, 0.62, 1.00, 0.55)
const _C_TITLE  = Color(0.55, 0.88, 1.00, 1.00)
const _C_SEP    = Color(0.28, 0.48, 0.82, 0.45)
const _C_KEY_BG = Color(0.16, 0.18, 0.24, 1.00)
const _C_KEY_BD = Color(0.42, 0.52, 0.75, 1.00)
const _C_KEY_TX = Color(1.00, 1.00, 0.92, 1.00)
const _C_ACTION = Color(0.82, 0.82, 0.82, 1.00)
const _C_HINT   = Color(0.55, 0.60, 0.70, 0.80)
const _C_SHADOW = Color(0.00, 0.00, 0.00, 0.90)

var _panel: Control
var _font: Font
var _can_dismiss := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load(_FONT_PATH)
	await get_tree().process_frame
	_build_panel()
	_animate_in()


func _input(event: InputEvent) -> void:
	if not _can_dismiss:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_dismiss()


func _build_panel() -> void:
	var vp := get_viewport_rect().size

	_panel = Control.new()
	_panel.custom_minimum_size = Vector2(_W, _H)
	_panel.size               = Vector2(_W, _H)
	_panel.position           = Vector2(-_W - 40.0, roundf(vp.y * 0.5 - _H * 0.5))
	_panel.modulate.a         = 0.0
	add_child(_panel)

	# background
	_rect(_panel, Vector2.ZERO, Vector2(_W, _H), _C_BG)

	# 4-side border
	_rect(_panel, Vector2(0,      0     ), Vector2(_W, 1),  _C_BORDER)
	_rect(_panel, Vector2(0,     _H - 1), Vector2(_W, 1),  _C_BORDER)
	_rect(_panel, Vector2(0,      0     ), Vector2(1, _H),  _C_BORDER)
	_rect(_panel, Vector2(_W - 1, 0     ), Vector2(1, _H),  _C_BORDER)

	# title separator
	_rect(_panel, Vector2(1, 16), Vector2(_W - 2, 1), _C_SEP)

	# title — plain text, sem emoji
	_label(_panel, "CONTROLES",
		Vector2(1, 2), Vector2(_W - 2, 13),
		12, _C_TITLE, HORIZONTAL_ALIGNMENT_CENTER)

	# key rows
	var row_y := 21.0
	var row_h := 16.0
	_row_arrows(_panel, row_y)
	_row_keys(_panel, ["ESPAÇO"], "Pular",     row_y + row_h * 1.0)
	_row_keys(_panel, ["E"],      "Interagir", row_y + row_h * 2.0)

	# bottom hint
	_rect(_panel, Vector2(1, _H - 18), Vector2(_W - 2, 1), _C_SEP)
	_row_esc_hint(_panel, _H - 17.0)


# ── rows ─────────────────────────────────────────────────────────────────────

func _row_arrows(parent: Control, y: float) -> void:
	var x := 5.0
	var kw := 18.0

	# seta esquerda
	x = _text_key(parent, "<", x, y, kw) + 2.0
	# seta direita (usando caracteres unicode de seta)
	x = _text_key(parent, ">", x, y, kw) + 4.0

	_label(parent, "—", Vector2(x, y + 1), Vector2(10, 13), 9, _C_SEP, HORIZONTAL_ALIGNMENT_CENTER)
	x += 12.0
	_label(parent, "Mover", Vector2(x, y + 2), Vector2(_W - x - 4.0, 11),
		10, _C_ACTION, HORIZONTAL_ALIGNMENT_LEFT)


func _row_keys(parent: Control, keys: Array, action: String, y: float) -> void:
	var x := 5.0
	for key in keys:
		x = _text_key(parent, key, x, y, _key_width(key)) + 3.0
	x += 2.0
	_label(parent, "—", Vector2(x, y + 1), Vector2(10, 13), 9, _C_SEP, HORIZONTAL_ALIGNMENT_CENTER)
	x += 12.0
	_label(parent, action, Vector2(x, y + 2), Vector2(_W - x - 4.0, 11),
		10, _C_ACTION, HORIZONTAL_ALIGNMENT_LEFT)


func _row_esc_hint(parent: Control, y: float) -> void:
	var x := 5.0
	x = _text_key(parent, "ESC", x, y, _key_width("ESC")) + 5.0
	_label(parent, "—", Vector2(x, y + 1), Vector2(10, 13), 9, _C_SEP, HORIZONTAL_ALIGNMENT_CENTER)
	x += 12.0
	_label(parent, "Fechar", Vector2(x, y + 2), Vector2(70.0, 11),
		9, _C_HINT, HORIZONTAL_ALIGNMENT_LEFT)
	_label(parent, "10s", Vector2(1, y + 2), Vector2(_W - 5.0, 11),
		8, _C_HINT, HORIZONTAL_ALIGNMENT_RIGHT)


# ── key drawing ───────────────────────────────────────────────────────────────

func _text_key(parent: Control, txt: String, x: float, y: float, kw: float) -> float:
	var kh := 13.0
	_rect(parent, Vector2(x + 1, y + 2), Vector2(kw, kh),         Color(0, 0, 0, 0.45))
	_rect(parent, Vector2(x,     y + 1), Vector2(kw, kh),         _C_KEY_BD)
	_rect(parent, Vector2(x + 1, y + 2), Vector2(kw - 2, kh - 2), _C_KEY_BG)
	_rect(parent, Vector2(x + 1, y + 2), Vector2(kw - 2, 1),      Color(1, 1, 1, 0.07))
	var fs := 7 if txt == "ESPAÇO" else 9
	_label(parent, txt, Vector2(x + 1, y + 2), Vector2(kw - 2, kh - 2),
		fs, _C_KEY_TX, HORIZONTAL_ALIGNMENT_CENTER)
	return x + kw


func _key_width(key: String) -> float:
	match key:
		"ESPAÇO": return 48.0
		"ESC":    return 28.0
		_:        return max(18.0, float(key.length()) * 5.5 + 12.0)


# ── primitives ────────────────────────────────────────────────────────────────

func _rect(parent: Control, pos: Vector2, sz: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color    = color
	r.position = pos
	r.size     = sz
	parent.add_child(r)
	return r


func _label(parent: Control, txt: String, pos: Vector2, sz: Vector2,
		font_sz: int, color: Color, h_align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.text     = txt
	l.position = pos
	l.size     = sz
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", font_sz)
	l.add_theme_color_override("font_color",        color)
	l.add_theme_color_override("font_shadow_color", _C_SHADOW)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.horizontal_alignment = h_align
	l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


# ── animation ─────────────────────────────────────────────────────────────────

func _animate_in() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.45).set_delay(0.5)
	tw.tween_property(_panel, "position:x", _MARGIN_L, 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.5)
	await tw.finished

	_can_dismiss = true

	await get_tree().create_timer(10.0).timeout
	if is_instance_valid(self) and _can_dismiss:
		_dismiss()


func _dismiss() -> void:
	if not _can_dismiss:
		return
	_can_dismiss = false
	set_process_input(false)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.35)
	tw.tween_property(_panel, "position:x", -_W - 40.0, 0.38) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished

	if is_instance_valid(self):
		queue_free()
