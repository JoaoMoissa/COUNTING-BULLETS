extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$AnimationPlayer.play("RESET")
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func resume():
	get_tree().paused = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$AnimationPlayer.play_backwards("blur")
	
func pause():
	get_tree().paused = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$AnimationPlayer.play("blur")
	
func testEsc():
	if Input.is_action_just_pressed("pause") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("pause") and get_tree().paused:
		resume()


func _on_resume_pressed():
	resume()
	
func _on_restart_pressed():
	get_tree().reload_current_scene()
	
func _on_quit_pressed():
	get_tree().quit()


func _process(_delta):
	testEsc()
