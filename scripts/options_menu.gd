extends Control

@onready var sensitivity_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SensitivitySlider
@onready var sensitivity_value: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SensitivityValue

var temporary_sensitivity: float


func _ready() -> void:
	temporary_sensitivity = Settings.mouse_sensitivity
	sensitivity_slider.value = temporary_sensitivity
	sensitivity_value.text = str(round(temporary_sensitivity * 1000.0))


func _on_sensitivity_slider_value_changed(value: float) -> void:
	temporary_sensitivity = value
	sensitivity_value.text = str(round(value * 1000.0))


func _on_save_changes_pressed() -> void:
	Settings.mouse_sensitivity = temporary_sensitivity
	hide()


func _on_cancel_pressed() -> void:
	temporary_sensitivity = Settings.mouse_sensitivity
	sensitivity_slider.value = temporary_sensitivity
	sensitivity_value.text = str(round(temporary_sensitivity * 1000.0))
	hide()


func open_menu() -> void:
	temporary_sensitivity = Settings.mouse_sensitivity
	sensitivity_slider.value = temporary_sensitivity
	sensitivity_value.text = str(round(temporary_sensitivity * 1000.0))
	show()
