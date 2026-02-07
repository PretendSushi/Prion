extends Enemy

func _physics_process(delta: float) -> void:
	super(delta)
	if player_in_range and can_move and !is_kbd:
		move(delta, direction)

func _on_detect_box_body_entered(body):
	find_player_direction(body)

func _on_detect_box_body_exited(body: Node2D) -> void:
	player_in_range = false
	direction = 0 
