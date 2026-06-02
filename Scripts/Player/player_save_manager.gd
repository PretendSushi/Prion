extends Node2D

#Modules
var abilities

func init():
	abilities = $"../Abilities"

func get_data_to_save():
	return {
		"last_save_point": RoomManager.last_save_point,
		"unlocked_abilities": abilities.get_unlocked_standard_abilities()
	}
 
func apply_save_data(data):
	set_last_save_point(data["last_save_point"])
	abilities.add_standard_abilities(data["unlocked_abilities"])
	global_position.x = data["last_save_point"]["player_x"]
	global_position.y = data["last_save_point"]["player_y"]

func set_last_save_point(save_dict: Dictionary):
	if not save_dict:
		print("Error. No data")
		return
	RoomManager.set_last_save_point(save_dict)
