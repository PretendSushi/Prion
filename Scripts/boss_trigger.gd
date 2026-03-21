extends Node2D

signal boss_camera

@export var left_bound: int
@export var right_bound: int

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		emit_signal("boss_camera", left_bound, right_bound, )
