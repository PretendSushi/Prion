extends Control

signal go_back

@onready var vbox = $VBoxContainer
@onready var controls = $ControlSettingsMenu
@onready var video = $VideoSettingsMenu

func _on_back_btn_pressed() -> void:
	emit_signal("go_back")

func _on_con_btn_pressed() -> void:
	vbox.visible = false
	controls.visible = true

func _on_control_settings_menu_back() -> void:
	vbox.visible = true
	controls.visible = false
	
func _on_vid_btn_pressed() -> void:
	vbox.visible = false
	video.visible = true

func _on_video_settings_menu_back() -> void:
	vbox.visible = true
	video.visible = false
