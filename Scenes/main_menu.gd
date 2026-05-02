extends Node2D

@onready var buttons = $VBoxContainer
@onready var settings = $SettingsMenu

func _on_new_btn_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/ApartmentRooms/level.tscn")

func _on_exit_btn_button_up() -> void:
	get_tree().quit()


func _on_sett_btn_button_up() -> void:
	buttons.visible = false
	settings.visible = true


func _on_settings_menu_back_button_pressed() -> void:
	print("hit")
	buttons.visible = true
	settings.visible = false


func _on_cont_btn_button_up() -> void:
	SaveManager.load_game(SaveManager.find_last_save())
