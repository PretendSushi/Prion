extends Node

const BASE_RES = 1080
const MAX_RES = 2160

var resolution := Vector2i(1920, 1080)
var window_size: DisplayServer
var zoom = 0.5

func on_setings_changed(res, win_size):
	resolution = res
	zoom = MAX_RES/res.y
	#window_size = win_size #OPCODE 28?!?!?!?!?!
	
func get_resolution():
	return resolution
	
func get_window_size():
	return window_size

func get_res_mult():
	return resolution.y/BASE_RES
	
func get_zoom():
	return zoom
