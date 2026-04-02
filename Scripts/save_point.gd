extends Interactable

@onready var text_label = $RichTextLabel

@export var room_id: int

var interaction_text = "smell the flowers"

func _process(delta: float) -> void:
	pass

func _display_text():
	var final_text = prompt_text + interaction_text
	text_label.text = final_text
	
func _remove_text():
	text_label.text = ""
	
func _on_interact(player):
	player.restore_max_hp()
	player.set_last_save_point(build_dict())
	CustomStatTracker.add_time_played()
	
func build_dict():
	return { "room_id": room_id, "player_x": global_position.x, "player_y": global_position.y}
