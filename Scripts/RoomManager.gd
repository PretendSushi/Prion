extends Node

var player_x = null
var player_y = null
var player_stats = null

func change_level(room_data):
	#get the players stats BEFORE changing the room
	var player = get_tree().get_nodes_in_group("Player")[0]
	player_stats = player.get_data_as_dict()
	#change the room
	get_tree().change_scene_to_file(get_room_path_by_id(room_data.room_id))
	#this is such a fucking hack...
	player_x = room_data.player_x
	player_y = room_data.player_y
	
func get_room_path_by_id(room_id):
	var file := FileAccess.open("res://Resources/RoomIDPaths.json", FileAccess.READ)
	if file == null:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var result = json.parse(content)
	if result == OK:
		for i in json.data:
			if str(room_id) == i["id"]:
				return i["path"]
	return null
	
func nullify_player_coords():
	player_x = null
	player_y = null
