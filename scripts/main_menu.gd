extends Control

@onready var options_menu: Control = $OptionsMenu

func _ready() -> void:
	options_menu.hide()
	
func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/wold.tscn")


func _on_options_pressed():
	options_menu.open_menu()

func _on_back_pressed() -> void:
	hide()
	
func _on_quit_pressed():
	get_tree().quit()
