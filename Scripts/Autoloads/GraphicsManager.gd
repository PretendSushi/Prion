extends Node

const BASE_RES = 1080
const MAX_RES = 2160

const WINDOWED_OPT_ID = 0
const FULLSCR_OPT_ID = 1
const BORDERL_OPT_ID = 2

const LOW_RES_ID = 0
const STAND_RES_ID = 1
const HIGH_RES_ID = 2
const ULTRA_RES_ID = 3

const PATH = "user://graphicssettings.json"

var resolution := Vector2i(1920, 1080)
var resolution_id
var window_size
var zoom = 0.5

func on_setings_changed(res, win_size, res_id):
	resolution = res
	resolution_id = res_id
	zoom = MAX_RES/res.y
	window_size = win_size #OPCODE 28?!?!?!?!?!
	save_settings({ "window_mode" : win_size, "resolution" : res_id })
	
func get_resolution():
	return resolution
	
func get_window_size():
	return window_size

func get_res_mult():
	return resolution.y/BASE_RES
	
func get_zoom():
	return zoom

func save_settings(settings):
	var config = FileAccess.open(PATH, FileAccess.WRITE)
	
	var data = {}
	
	data["window_mode"] = settings["window_mode"]
	data["resolution"] = settings["resolution"]
	
	var updated_json = JSON.stringify(data, "\t")
	
	config.store_string(updated_json)
	config.close()

func load_settings():
	var config = FileAccess.open(PATH, FileAccess.READ)
	if config:
		var content = config.get_as_text()
		config.close()
		var data = JSON.parse_string(content)
		
		return data
		
func apply_settings(settings):
	var selected_res = 0
	var res_id = int(settings["resolution"])
	match settings["window_mode"]:
		WINDOWED_OPT_ID:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		FULLSCR_OPT_ID:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		BORDERL_OPT_ID:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			
	match int(settings["resolution"]):
		LOW_RES_ID:
			get_window().content_scale_size = (Vector2i(1280, 720))
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			selected_res = 720
			res_id = LOW_RES_ID
		STAND_RES_ID:
			get_window().content_scale_size = (Vector2i(1920, 1080))
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			selected_res = 1080
			res_id = STAND_RES_ID
		HIGH_RES_ID:
			get_window().content_scale_size = (Vector2i(2560, 1440))
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			selected_res = 1440
			res_id = HIGH_RES_ID
		ULTRA_RES_ID:
			get_window().content_scale_size = (Vector2i(3840, 2160))
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			selected_res = 2160
			res_id = ULTRA_RES_ID
	var camera = get_tree().get_first_node_in_group("Camera")
	if camera and selected_res != 0:
		camera.change_zoom(2160, selected_res)
	on_setings_changed(get_window().content_scale_size, DisplayServer.WINDOW_MODE_FULLSCREEN, res_id)

func rebuild_settings():
	await get_tree().process_frame
	var graph_set = get_tree().get_first_node_in_group("GraphicsSettings")
	if graph_set and window_size != null and resolution_id != null:
		graph_set.set_settings(window_size, resolution_id)

func config_exists():
	return FileAccess.file_exists(PATH)
