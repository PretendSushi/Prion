extends Node2D

@export var room_trans_data: RoomTransData

func _ready():
	pass
	
func _on_detect_box_body_entered(body: Node2D) -> void:
	RoomManager.change_level(room_trans_data)
