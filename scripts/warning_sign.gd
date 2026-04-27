extends Node2D

@onready var interaction_icon: CanvasItem = $texture
@onready var interaction_area: Area2D = $area_sign

const DIALOG_LINES: Array[String] = [
	"Guardião... até que enfim você acordou...",
	"Eu estava procurando por você... a floresta precisa da sua ajuda.",

	"Durante a noite... algo aconteceu.",
	"Um fogo começou a se espalhar no coração da mata...",
	"mas não era um fogo comum...",
	"a fumaça era densa... escura... quase viva.",

	"Desde então... tudo mudou.",
	"O vento ficou pesado... as árvores estão inquietas...",
	"e os animais... estão fugindo... ou desaparecendo.",

	"Eu sinto uma presença... fria... silenciosa...",
	"como uma sombra que cresce sem ser vista...",
	"mas eu não consigo entender o que é...",

	"Você é o guardião...",
	"a floresta sempre confiou em você...",
	"e agora ela precisa mais do que nunca.",

	"Vá até o coração da floresta...",
	"descubra o que está acontecendo...",
	"antes que essa escuridão se espalhe ainda mais..."
]

var player_inside := false


func _ready() -> void:
	interaction_icon.hide()
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not player_inside:
		return

	if DialogManager.is_message_active:
		return

	if event.is_action_pressed("interact"):
		interaction_icon.hide()
		DialogManager.start_message(global_position, DIALOG_LINES)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if not DialogManager.is_message_active:
			interaction_icon.show()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
		interaction_icon.hide()
		close_dialog()


func close_dialog() -> void:
	if DialogManager.dialog_box != null:
		DialogManager.dialog_box.queue_free()
		DialogManager.dialog_box = null

	DialogManager.is_message_active = false
	DialogManager.can_advance_message = false
	DialogManager.current_line = 0
	DialogManager.message_lines.clear()
