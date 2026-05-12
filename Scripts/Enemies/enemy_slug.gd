extends Enemy

func _physics_process(delta: float) -> void:
	super(delta)
	if player_in_range and can_move and !is_kbd:
		move(delta, direction)

func _on_detect_box_body_entered(body):
	if is_body_player(body):
		player_in_range = true
	find_player_direction(body)

func _on_detect_box_body_exited(body: Node2D) -> void:
	if is_body_player(body):
		player_in_range = false
		velocity.x = 0 
	direction = 0 
