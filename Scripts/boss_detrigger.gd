extends Node2D

signal deboss_camera

func _on_area_2d_body_entered(body: Node2D) -> void:
	emit_signal("deboss_camera")
