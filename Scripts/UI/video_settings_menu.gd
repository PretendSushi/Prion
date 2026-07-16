extends Control

signal back

const WINDOWED_OPT_ID = 0
const FULLSCR_OPT_ID = 1
const BORDERL_OPT_ID = 2

const LOW_RES_ID = 0
const STAND_RES_ID = 1
const HIGH_RES_ID = 2
const ULTRA_RES_ID = 3

@onready var screen_mode = $VBoxContainer/ScreenMode
@onready var resolution = $VBoxContainer/Resolution

func _on_apply_btn_pressed() -> void:
	GraphicsManager.apply_settings({"window_mode" : screen_mode.get_selected_id(), "resolution": resolution.get_selected_id()})

func _on_back_btn_pressed() -> void:
	emit_signal("back")

func set_settings(window_mode, resolution_id):
	screen_mode.selected = window_mode
	resolution.selected = resolution_id
