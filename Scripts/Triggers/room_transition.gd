extends Node2D

@export var room_trans_data: RoomTransData

func _ready():
	pass
	
func _on_detect_box_body_entered(body: Node2D) -> void:
	if body == get_tree().get_nodes_in_group("Player")[0]:
		RoomManager.change_level(room_trans_data)
