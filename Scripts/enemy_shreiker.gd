extends Enemy


func _physics_process(delta: float) -> void:
	super(delta)
	if player_in_range and is_player_moving():
		pass
	
func _on_detect_box_body_entered(body):
	find_player_direction(body)

func _on_detect_box_body_exited(body: Node2D) -> void:
	direction = 0 

func is_player_moving():
	var player = get_tree().get_nodes_in_group("Player")[0]
	if player:
		return player.movement_state == player.MovementState.WALKING
	return false
