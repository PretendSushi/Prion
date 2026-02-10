extends Enemy

const OVERSHOT_MOD = 0.5
const VELOCITY_CAP = 1000

var player
var overshot
var player_last_x
var target_loc

enum MovementState { IDLE, MOVING }

var movement_state : MovementState

func _ready() -> void:
	speed = 400.0
	movement_state = MovementState.IDLE

func _physics_process(delta: float) -> void:
	super(delta)
	if player and overshot:
		move(delta, direction)
	#if player_in_range and is_player_moving() and player:
		#get_overshot(player)
		#get_player_last_x(player)
	if player:
		get_target_loc(player)
	handle_states()
	play_animations(direction)
		
func move(delta, direction):
	if target_loc:
		if direction > 0:
			if global_position.x < (target_loc):
				calculate_speed()
			else:
				velocity.x = 0
		elif direction < 0:
			if global_position.x > (target_loc):
				calculate_speed()
			else:
				velocity.x = 0 
		else:
			velocity.x = 0
	else:
		velocity.x = 0

func calculate_speed():
	if abs(velocity.x) + speed > VELOCITY_CAP:
		if abs(velocity.x) < VELOCITY_CAP:
			velocity.x = VELOCITY_CAP * direction
	else:
		velocity.x += speed * direction 
		
func _on_detect_box_body_entered(body):
	if is_body_player(body):
		player_in_range = true
		player = body
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
	
func play_animations(direction):
	var target_anim = ""
	
	if movement_state == MovementState.MOVING:
		target_anim = "move"
	else:
		target_anim = "idle"
	
	if direction > 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
		
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)
	
func handle_states():
	if velocity.x != 0:
		movement_state = MovementState.MOVING
	else:
		movement_state = MovementState.IDLE

func get_target_loc(body):
	if player_in_range and is_player_moving() and is_body_player(body):
		get_player_last_x(body)
		get_overshot(body)
		if direction > 0:
			target_loc = player_last_x - overshot
		elif direction < 0:
			target_loc = player_last_x - overshot
