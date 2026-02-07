extends Enemy

const OVERSHOT_MOD = 0.05

var player
var overshot
var player_last_x

func _ready() -> void:
	speed = 400.0

func _physics_process(delta: float) -> void:
	super(delta)
	print(player_in_range)
	if player_in_range and is_player_moving() and player and overshot:
		move(delta, direction)
		
func move(delta, direction):
	if global_position.x != (player_last_x + overshot):
		if direction:
			velocity.x += direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
	animated_sprite.play("move")
	
func _on_detect_box_body_entered(body):
	if is_body_player(body):
		player_in_range = true
		player = body
		get_overshot(body)
		get_player_last_x(body)
	find_player_direction(body)

func _on_detect_box_body_exited(body: Node2D) -> void:
	if is_body_player(body):
		player_in_range = false

func is_player_moving():
	if get_tree().get_nodes_in_group("Player"):
		var player = get_tree().get_nodes_in_group("Player")[0]
		if player:
			return player.movement_state == player.MovementState.WALKING
		return false

func get_player_coords(body):
	if is_body_player(body):
		return body.global_position
		
func get_overshot(player):
	var player_coords = get_player_coords(player)
	overshot = (global_position.x - player_coords.x) * OVERSHOT_MOD
	
func get_player_last_x(body):
	player_last_x = get_player_coords(body).x
	
