extends Node

const PATH = "user://saves/"
var file_template = "save"
var file_format = ".json"

func save_game():
	#create the file
	var save_file = FileAccess.open(PATH + generate_save_file_name(), FileAccess.WRITE)
	#get the data that needs to be saved
	var player_node = get_tree().get_first_node_in_group("Player")
	var level_node = get_tree().current_scene
	
	var data = {}
	
	data["player_data"] = player_node.get_data_to_save()
	data["level_data"] = level_node.get_data_to_save()
	
	var updated_json = JSON.stringify(data, "\t")
	save_file.store_string(updated_json)
	save_file.close()
	
func load_game(file_name):
	var file = FileAccess.open(PATH + file_name, FileAccess.READ)
	
	if file:
		var content = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)
		
		var room_path = RoomManager.get_room_path_by_id(int(data["level_data"]["room_id"]))
		
		if room_path == null:
			print("Failed to load data in file: " + PATH + file_name)
		
		get_tree().change_scene_to_file(room_path)
		
		RoomManager.set_room_data({"room_id": int(data["level_data"]["room_id"]),
									"player_x": data["player_data"]["last_save_point"]["player_x"],
									"player_y": data["player_data"]["last_save_point"]["player_y"]})
	else:
		print("Failed to open file at: " + PATH + file_name)
		return false

func find_last_save():
	var dir = DirAccess.open(PATH)
	if dir:
		if dir.get_files().is_empty() and dir.get_directories().is_empty():
			print("No files in directory")
		else:
			var files = DirAccess.get_files_at(PATH)
			var last_edited = files[0]
			for file in files:
				if !is_valid_save_file(file):
					continue
				if FileAccess.get_modified_time(PATH + file) > FileAccess.get_modified_time(PATH + last_edited):
					last_edited = file
			return last_edited

func is_valid_save_file(file):
	for i in file_template.length():
		if file_template[i] != file[i]:
			return false
	
	file = file.split("")
	var file_end = file.slice(-file_format.length())
	file_end = "".join(file_end)
	if file_end != file_format:
		return false
		
	return true

func generate_save_file_name():
	#first save, save1.json
	if !DirAccess.dir_exists_absolute(PATH):
		return file_template + "1" + file_format
		
	var dir = DirAccess.open(PATH)
	if dir:
		if dir.get_files().is_empty() and dir.get_directories().is_empty():
			#if the folder exists but not the file for some reason, it's still the first save, save1.json
			return file_template + "1" + file_format
		else:
			#otherwise, find the last save number and increase it by 1, and add it to the save file name
			var files = DirAccess.get_files_at(PATH)
			var last_save = files[files.size()-1]
			var save_num = ""
			for i in range(file_template.length(),last_save.length()):
				if last_save[i] != ".":
					save_num += last_save[i]
				else:
					break
			var save_int = save_num.to_int()
			save_int += 1
			save_num = str(save_int)
			print(file_template + save_num)
			return file_template + save_num + file_format
	else:
		print("Game could not be saved")
