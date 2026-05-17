extends Control

# ----------------------------------------------------------------------------
# Tela de creditos finais
# ----------------------------------------------------------------------------
# A lista e montada por codigo para manter todos os creditos de assets em um
# lugar so. Entradas com autor/licenca nao encontrados no projeto ficam
# marcadas desse jeito, sem inventar informacao.
# ----------------------------------------------------------------------------

const TITLE_SCENE := "res://scenes/title_screen.tscn"
const FONT_PATH := "res://assets/Extras/fonts/RevMiniPixel.ttf"

@export var scroll_speed: float = 34.0

@onready var content: VBoxContainer = $scroll/content
@onready var scroll: Control = $scroll
@onready var prompt: Label = $prompt

var finished: bool = false
var content_height: float = 0.0
var scroll_offset: float = 0.0
var _font: Font
var _base_scroll_speed: float = 26.0

var _credits := [
	{"type": "title", "text": "PLATAFORM 2D GODOT 4.0"},
	{"type": "body", "text": "Obrigado por jogar"},
	{"type": "space", "size": 60},

	{"type": "section", "text": "DESENVOLVIMENTO"},
	{"type": "name", "text": "Gabriel Holanda, Paulo Sergio, Breno Sadoke, José Rafael, Vinicius Kauã, Pablo Café, Victor Milito"},
	{"type": "body", "text": "Game design, programacao, fases, integracao e historia"},
	{"type": "space", "size": 44},

	{"type": "section", "text": "ARTE, TILESETS E PERSONAGENS"},
	{"type": "name", "text": "GrafxKid"},
	{"type": "body", "text": "Sprite Pack 2; Sprite Pack 8; Mini FX, Items & UI; Seasonal Tilesets"},
	{"type": "small", "text": "Licenca encontrada: CC0 1.0 Universal Public Domain"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "YanSan / @yansan1902"},
	{"type": "body", "text": "Jungle Asset Pack: tilemap, backgrounds, grama, pedras, plantas, arvores e placas"},
	{"type": "small", "text": "README encontrado em assets/amazon/Platformer_Jungle Asset Pack"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "YanSan / @yansan1902"},
	{"type": "body", "text": "Forest Monsters: Mushroom with VFX e Mushroom without VFX"},
	{"type": "small", "text": "Autor inferido pela pasta amazon/YanSan; README especifico nao encontrado no projeto"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "LuizMelo"},
	{"type": "body", "text": "Martial Hero Asset Pack"},
	{"type": "small", "text": "Licenca encontrada: Creative Commons Zero (CC0)"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "LuizMelo"},
	{"type": "body", "text": "Monsters Creatures Fantasy: Skeleton, Goblin, Mushroom e Flying Eye"},
	{"type": "small", "text": "Credito mantido pelo pacote usado no projeto; arquivo de licenca separado nao encontrado"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "David Marah / @aethrall"},
	{"type": "body", "text": "Demon Woods parallax pack"},
	{"type": "small", "text": "Licenca encontrada: uso comercial permitido; credito apreciado, nao obrigatorio"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "DeepGlowing"},
	{"type": "body", "text": "Dead Forest Asset Pack: tiles e backgrounds da floresta morta"},
	{"type": "small", "text": "Author note encontrado: assets free para uso comercial com credito"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "Distant Forest - World 2"},
	{"type": "body", "text": "Green Forest, Swamp Forest e Taiga Forest"},
	{"type": "small", "text": "Autor/licenca nao encontrados nos arquivos locais do projeto"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "Dark Fantasy Enemies FREE"},
	{"type": "body", "text": "Bat with VFX e Bat without VFX"},
	{"type": "small", "text": "Autor/licenca nao encontrados nos arquivos locais do projeto"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "Flying Forest Enemies FREE"},
	{"type": "body", "text": "Enemy3 movement e no-movement animation"},
	{"type": "small", "text": "Autor/licenca nao encontrados nos arquivos locais do projeto"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "CreativeKind"},
	{"type": "body", "text": "Necromancer_creativekind-Sheet"},
	{"type": "small", "text": "Credito inferido pelo nome do arquivo; licenca nao encontrada no projeto"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "Skeleton Enemy"},
	{"type": "body", "text": "Skeleton enemy sprite sheet"},
	{"type": "small", "text": "Autor/licenca nao encontrados nos arquivos locais do projeto"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "FlyingObelisk"},
	{"type": "body", "text": "FlyingObelisk_no_lightnings_no_letter"},
	{"type": "small", "text": "Autor/licenca nao encontrados nos arquivos locais do projeto"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "Fox Sprites 2D Pixel"},
	{"type": "body", "text": "Fox Sprite Sheet e facesets da Raposa"},
	{"type": "small", "text": "Autor/licenca nao encontrados nos arquivos locais do projeto"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "Cave Tileset"},
	{"type": "body", "text": "tileset-cave e backgrounds de caverna"},
	{"type": "small", "text": "Autor/licenca nao encontrados nos arquivos locais do projeto"},
	{"type": "space", "size": 18},

	{"type": "name", "text": "Extras UI"},
	{"type": "body", "text": "Botoes de toque: setas esquerda, direita e pulo"},
	{"type": "small", "text": "Autor/licenca nao encontrados nos arquivos locais do projeto"},
	{"type": "space", "size": 46},

	{"type": "section", "text": "FONTE"},
	{"type": "name", "text": "RevMiniPixel"},
	{"type": "body", "text": "Fonte pixel usada na HUD, dialogos, menus e creditos"},
	{"type": "small", "text": "Arquivo local: assets/Extras/fonts/RevMiniPixel.ttf; licenca nao encontrada no projeto"},
	{"type": "space", "size": 46},

	{"type": "section", "text": "AUDIO"},
	{"type": "body", "text": "bg_music, warriorfight, jump_sfx, hitbox_sfx, coin_sfx e break_sfk"},
	{"type": "small", "text": "Autor/licenca nao encontrados nos arquivos locais do projeto"},
	{"type": "space", "size": 46},

	{"type": "section", "text": "ENGINE"},
	{"type": "name", "text": "Godot Engine 4"},
	{"type": "body", "text": "godotengine.org"},
	{"type": "small", "text": "Licenca MIT"},
	{"type": "space", "size": 54},

	{"type": "section", "text": "AGRADECIMENTOS"},
	{"type": "body", "text": "A todos os criadores que disponibilizaram assets para jogos independentes"},
	{"type": "body", "text": "E a voce, Guardiao, por restaurar a floresta"},
	{"type": "space", "size": 54},

	{"type": "section", "text": "OBSERVACAO DE CREDITOS"},
	{"type": "small", "text": "Foram creditados todos os pacotes de assets encontrados e usados no projeto. Quando nao havia README/licenca local, isso foi indicado nos creditos."},
	{"type": "space", "size": 70},

	{"type": "title", "text": "FIM"},
	{"type": "body", "text": "A floresta vai lembrar de voce."},
	{"type": "space", "size": 120},
]


func _ready() -> void:
	_base_scroll_speed = scroll_speed
	_font = load(FONT_PATH)
	if prompt:
		prompt.visible = false
		prompt.text = ""
		prompt.modulate.a = 0.0
	_build_credits()
	_play_intro()

	await get_tree().process_frame
	await get_tree().process_frame
	content_height = maxf(content.get_combined_minimum_size().y, content.size.y)
	var screen_h: float = scroll.size.y
	if screen_h <= 0.0:
		screen_h = float(get_viewport_rect().size.y)
	scroll_offset = minf(screen_h * 0.68, 520.0)
	content.position = Vector2(maxf((scroll.size.x - content.custom_minimum_size.x) * 0.5, 24.0), scroll_offset)


func _process(delta: float) -> void:
	if finished:
		return
	scroll_offset -= scroll_speed * delta
	content.position.y = scroll_offset

	var screen_h: float = scroll.size.y
	if screen_h <= 0.0:
		screen_h = float(get_viewport_rect().size.y)
	var stop_at: float = -content_height + screen_h * 0.5
	if scroll_offset <= stop_at:
		scroll_offset = stop_at
		content.position.y = stop_at
		finished = true


func _build_credits() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	content.custom_minimum_size = Vector2(560, 0)
	content.add_theme_constant_override("separation", 7)

	for entry in _credits:
		if entry["type"] == "space":
			_add_space(float(entry["size"]))
		else:
			_add_label(str(entry["text"]), str(entry["type"]))


func _add_space(height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	content.add_child(spacer)


func _add_label(text: String, kind: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = 3
	label.custom_minimum_size = Vector2(560, 0)
	label.add_theme_font_override("font", _font)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))

	match kind:
		"title":
			label.add_theme_font_size_override("font_size", 34)
			label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.58, 1.0))
			label.add_theme_constant_override("outline_size", 6)
		"section":
			label.add_theme_font_size_override("font_size", 22)
			label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.68, 1.0))
			label.add_theme_constant_override("outline_size", 5)
		"name":
			label.add_theme_font_size_override("font_size", 17)
			label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1.0))
			label.add_theme_constant_override("outline_size", 4)
		"small":
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", Color(0.68, 0.72, 0.76, 1.0))
			label.add_theme_constant_override("outline_size", 0)
		_:
			label.add_theme_font_size_override("font_size", 13)
			label.add_theme_color_override("font_color", Color(0.90, 0.92, 0.88, 1.0))
			label.add_theme_constant_override("outline_size", 2)

	content.add_child(label)


func _play_intro() -> void:
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.7)


func _unhandled_input(_event: InputEvent) -> void:
	return
