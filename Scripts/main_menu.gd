extends Node2D

@onready var buttons = $VBoxContainer
@onready var settings = $SettingsMenu
@onready var loads = $SaveList

func _on_new_btn_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/ApartmentRooms/level.tscn")

func _on_exit_btn_button_up() -> void:
	get_tree().quit()


func _on_sett_btn_button_up() -> void:
	buttons.visible = false
	settings.visible = true

func _on_settings_menu_back_button_pressed() -> void:
	buttons.visible = true
	settings.visible = false

func _on_cont_btn_button_up() -> void:
	SaveManager.load_game(SaveManager.find_last_save())

func _on_load_btn_pressed() -> void:
	buttons.visible = false
	loads.visible = true


func _on_save_list_back_button_pressed() -> void:
	buttons.visible = true
	loads.visible = false
