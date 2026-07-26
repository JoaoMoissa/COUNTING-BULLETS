extends Node3D

@onready var prompt: Label3D = $Area3D/Prompt
@onready var area: Area3D = $Area3D

var player_in_range: bool = false

func _ready() -> void:
	prompt.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		prompt.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		prompt.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		_open()

func _open() -> void:
	if MissionManager.has_active_mission():
		print("[BOARD] Conclua sua missão atual primeiro")   # passo 4: mostrar na tela
		return
	var ui = get_tree().get_first_node_in_group("MissionUI")
	if ui:
		ui.open()
