extends Pickupable

func _ready():
	pass

func _on_detect_box_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		emit_signal("picked_up")
		queue_free()
