extends Node

const BASE_RES = 1080

var resolution := Vector2i(1920, 1080)
var window_size: DisplayServer

func on_setings_changed(res, win_size):
	resolution = res
	#window_size = win_size
	
func get_resolution():
	return resolution
	
func get_window_size():
	return window_size

func get_res_mult():
	return resolution.y/BASE_RES
