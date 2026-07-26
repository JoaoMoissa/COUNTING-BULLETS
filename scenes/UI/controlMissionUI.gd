extends Control

@onready var buttons: Array = [$Panel/Option1, $Panel/Option2, $Panel/Option3]
var options: Array = []
var is_open := false

func _ready() -> void:
	hide()
	for i in buttons.size():
		buttons[i].pressed.connect(_on_option_pressed.bind(i))

func open() -> void:
	is_open = true
	
	if options.is_empty():
		options = MissionManager.offer_missions()

	for i in buttons.size():
		var m = options[i]
		buttons[i].text = "%s\nRecompensa: %s" % [m.description, m.reward_text]
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_option_pressed(index: int) -> void:
	MissionManager.accept(options[index])
	_close()

func _close() -> void:
	is_open = false
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
