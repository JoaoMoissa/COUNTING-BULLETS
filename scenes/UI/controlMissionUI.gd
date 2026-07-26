extends Control

@onready var buttons: Array = [$Panel/Option1, $Panel/Option2, $Panel/Option3]
var options: Array = []

func _ready() -> void:
	hide()
	for i in buttons.size():
		buttons[i].pressed.connect(_on_option_pressed.bind(i))

func open() -> void:
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
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
