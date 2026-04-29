extends Node

const PATH = "user://saves/"
var file_template = "save"

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
	
func generate_save_file_name():
	#first save, save1.json
	if !DirAccess.dir_exists_absolute(PATH):
		return file_template + "1" + ".json"
		
	var dir = DirAccess.open(PATH)
	if dir:
		if dir.get_files().is_empty() and dir.get_directories().is_empty():
			#if the folder exists but not the file for some reason, it's still the first save, save1.json
			return file_template + "1" + ".json"
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
			return file_template + save_num + ".json"
	else:
		print("Game could not be saved")
