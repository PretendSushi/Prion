extends Node

const FILEPATH = "user://Stats.json"

var deaths = 0
var kills = 0
var last_save_time
var time_played

func add_death():
	deaths += 1
	
func add_kill():
	kills += 1
	
func add_time_played():
	if !last_save_time:
		last_save_time = Time.get_unix_time_from_system()
		return
	time_played += last_save_time - Time.get_unix_time_from_system()
	
func save():
		
	var data = {}
	var file := FileAccess.open(FILEPATH, FileAccess.READ)
	
	if !FileAccess.file_exists(FILEPATH):
		var file_write = FileAccess.open(FILEPATH, FileAccess.WRITE)
		
		denull_stats()
		
		data["deaths"] = deaths
		data["kills"] = kills
		data["time_played"] = time_played
		
		var updated_json = JSON.stringify(data, "\t")
		file_write.store_string(updated_json)
		file_write.close()
		
	if file != null:
		var json_string = file.get_as_text()
		file.close()
		
		var result = JSON.parse_string(json_string)
		if result == null:
			print("Failed to parse JSON.")
			return
			
		data = result
	
	data["deaths"] += deaths
	data["kills"] += kills
	data["time_played"] += time_played
	
	var file_write := FileAccess.open(FILEPATH, FileAccess.WRITE)
	if file_write == null:
		file_write = FileAccess.open(FILEPATH, FileAccess.WRITE)
	if file_write:
		var updated_json = JSON.stringify(data, "\t")
		file_write.store_string(updated_json)
		file_write.close()
		print("JSON file updated successfully")
	else:
		print("Failed to open file for writing")
	
func denull_stats():
	if deaths == null:
		deaths = 0
	if kills == null:
		kills = 0
	if time_played == null:
		time_played = 0
		
