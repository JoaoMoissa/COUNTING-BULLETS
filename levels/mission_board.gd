extends Node3D

@onready var prompt: Label3D = $Area3D/Prompt
@onready var area: Area3D = $Area3D

var player_in_range: bool = false
var warning_id: int = 0

func _ready() -> void:
	prompt.text = "PRESS E"
	prompt.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		prompt.text = "PRESS E"
		prompt.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		warning_id += 1
		prompt.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		_open()

func _open() -> void:
	if MissionManager.has_active_mission():
		_show_active_mission_warning()
		return
	var ui = get_tree().get_first_node_in_group("MissionUI")
	if ui:
		ui.open()
		
func _show_active_mission_warning() -> void:
	warning_id += 1
	var current_warning: int = warning_id
	prompt.text = "FINISH YOUR ACTIVE MISSION FIRST!"
	prompt.visible = true

	await get_tree().create_timer(2.0).timeout

	if current_warning != warning_id:
		return
		
	if player_in_range:
		prompt.text = "PRESS E"
	else:
		prompt.visible = false
