extends Control

@onready var buttons = $VBoxContainer
@onready var options = $SettingsMenu

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Pause"):
		get_tree().paused = !get_tree().paused
		visible = !visible

func _on_continue_btn_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_exit_btn_pressed() -> void:
	get_tree().quit()


func _on_settings_btn_pressed() -> void:
	buttons.visible = false
	options.visible = true
	
