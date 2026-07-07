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
	var selected_res = 0
	match screen_mode.get_selected_id():
		WINDOWED_OPT_ID:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		FULLSCR_OPT_ID:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		BORDERL_OPT_ID:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			
	match resolution.get_selected_id():
		LOW_RES_ID:
			get_window().content_scale_size = (Vector2i(1280, 720))
			#get_window().content_scale_factor = 0.33333
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			selected_res = 720
		STAND_RES_ID:
			get_window().content_scale_size = (Vector2i(1920, 1080))
			#get_window().content_scale_factor = 0.5
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			selected_res = 1080
		HIGH_RES_ID:
			get_window().content_scale_size = (Vector2i(2560, 1440))
			#get_window().content_scale_factor = 0.75
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			selected_res = 1440
		ULTRA_RES_ID:
			get_window().content_scale_size = (Vector2i(3840, 2160))
			#get_window().content_scale_factor = 1
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			selected_res = 2160
	var camera = get_tree().get_first_node_in_group("Camera")
	if camera:
		camera.change_zoom(2160, selected_res)

func _on_back_btn_pressed() -> void:
	emit_signal("back")
