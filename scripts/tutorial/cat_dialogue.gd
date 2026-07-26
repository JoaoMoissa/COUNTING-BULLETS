extends Control

signal dialogue_finished

@onready var dialogue_label: Label = $DialogueLabel
@onready var continue_label: Label = $ContinueLabel

var dialogue_lines: Array = []
var current_line: int = 0
var is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func start_dialogue(lines: Array) -> void:
	dialogue_lines = lines
	current_line = 0
	is_open = true

	dialogue_label.text = dialogue_lines[current_line]
	continue_label.text = "PRESS ENTER"

	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	if event.is_action_pressed("ui_accept"):
		_next_line()
		get_viewport().set_input_as_handled()


func _next_line() -> void:
	current_line += 1

	if current_line >= dialogue_lines.size():
		close_dialogue()
		return

	dialogue_label.text = dialogue_lines[current_line]


func close_dialogue() -> void:
	is_open = false
	hide()

	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	dialogue_finished.emit()
