extends Control

@onready var quit_popup: Control = $QuitPopUp
@onready var options_menu: Control = $OptionsMenu

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$AnimationPlayer.play("RESET")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	quit_popup.hide()
	options_menu.hide()
	hide()

func resume():
	quit_popup.hide()
	options_menu.hide()
	hide()
	
	var focused_control := get_viewport().gui_get_focus_owner()
	if focused_control:
		focused_control.release_focus()
	
	get_tree().paused = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$AnimationPlayer.play_backwards("blur")
	
func pause():
	show()
	get_tree().paused = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$AnimationPlayer.play("blur")
	
func testEsc():
	if not Input.is_action_just_pressed("pause"):
		return

	var player = get_tree().get_first_node_in_group("Player")
	
	if player != null and player.is_dead:
		return
	
	if quit_popup.visible:
		quit_popup.hide()
	elif options_menu.visible:
		options_menu.hide()
	elif get_tree().paused:
		resume()
	else:
		pause()


func _on_resume_pressed():
	resume()
	
func _on_restart_pressed():
	get_tree().reload_current_scene()
	
func _on_quit_pressed():
	quit_popup.show()


func _process(_delta):
	testEsc()

func _on_yes_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func _on_no_pressed() -> void:
	quit_popup.hide()


func _on_options_pressed() -> void:
	options_menu.open_menu()
