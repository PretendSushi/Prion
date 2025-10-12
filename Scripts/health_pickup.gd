extends Node2D

signal picked_up

@onready var area2d = $Area2D

func _ready():
	pass
	
func _physics_process(delta: float) -> void:
	pass

func _on_detect_box_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		emit_signal("picked_up")
		queue_free()
