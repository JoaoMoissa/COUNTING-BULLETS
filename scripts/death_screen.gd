extends Control

@onready var final_score_label: Label = ($Background/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FinalScoreLabel)

func _ready() -> void:
	hide()

func show_death_screen(final_score: int) -> void:
	final_score_label.text = "SCORE: %d" % final_score
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_try_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
