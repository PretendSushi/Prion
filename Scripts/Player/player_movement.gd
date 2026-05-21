extends Node2D

enum Directions { LEFT, RIGHT }

var direction_lit
var direction = 0

#Constants
const JUMP_FORCE_FROM_WALL = 300
const JUMP_VELOCITY = -800.0
const JUMP_FORCE = 3000
const DASH_VELOCITY = 1500
const DASH_PROTEIN_COST = 5
const SPRINT_SPEED = 1400.0
const GROUND_SPEED = 700.0
const AIR_SPEED = 900.0
const JUMP_CAP = 400 #max jump height in pixels
const ROOM_ENTRANCE_AIR_TIME = 0.05
const ROOM_ENTRANCE_HORIZONTAL_TIME = 0.2

#Nodes
var player
var animated_sprite

#Modules
var state_machine
var player_timers
var collisions

#Flags
var jump_cancelled
var double_jump_cancelled
var jump_from_wall_cling

#Values
var jump_start_y

func init():
	player = $".."
	animated_sprite = $"../AnimatedSprite2D"
	state_machine = $"../StateMachine"
	player_timers = $"../Timers"
	collisions = $"../Collisions"
	
	direction_lit = Directions.RIGHT
	
	jump_cancelled = false
	double_jump_cancelled = false
	jump_from_wall_cling = false
	
	jump_start_y = 0

func move(delta):
	if state_machine.get_rubber_band_state() == state_machine.RubberBandState.STICKY_BAND\
	or player_timers.get_jump_off_flag()\
	or state_machine.get_transition_state() == state_machine.TransitionState.TRANSITIONING\
	or state_machine.get_movement_state() == state_machine.MovementState.DASH:
		return
		
	if state_machine.get_action_state() != state_machine.ActionState.RUBBER_BAND and state_machine.get_action_state() != state_machine.ActionState.LEECH:
		if Input.is_action_pressed("Left"):
			direction = -1.0
			direction_lit = Directions.LEFT
			if state_machine.get_movement_state() != state_machine.MovementState.JUMPING\
			and player_timers.handle_step_sfx_timer(delta):
				player.play_sounds(player.SoundEffects.WALK)
			state_machine.set_walking_state(state_machine.WalkingState.WALKING)
		elif Input.is_action_pressed("Right"):
			direction = 1.0
			direction_lit = Directions.RIGHT
			if state_machine.get_movement_state() != state_machine.MovementState.JUMPING\
			and player_timers.handle_step_sfx_timer(delta):
				player.play_sounds(player.SoundEffects.WALK)
			state_machine.set_walking_state(state_machine.WalkingState.WALKING)
			
		if state_machine.get_movement_state() == state_machine.MovementState.JUMPING:
			player.velocity.x = direction * AIR_SPEED
		elif state_machine.get_movement_state() == state_machine.MovementState.SPRINTING:
			player.velocity.x = direction * SPRINT_SPEED
		else:
			player.velocity.x = direction * GROUND_SPEED
			state_machine.set_movement_state(state_machine.MovementState.WALKING)
		
		if !Input.is_action_pressed("Left") and !Input.is_action_pressed("Right"):
			player.velocity.x = 0
			if state_machine.get_movement_state() != state_machine.MovementState.JUMPING:
				state_machine.set_movement_state(state_machine.MovementState.IDLE)
			state_machine.set_walking_state(state_machine.WalkingState.IDLE)

	#Flip sprite
	if direction_lit == Directions.RIGHT:
		animated_sprite.flip_h = false
	elif direction_lit == Directions.LEFT:
		animated_sprite.flip_h = true
		
func handle_jump(delta):
	if state_machine.get_action_state() == state_machine.ActionState.WALL_CLING:
		jump_cancelled = false
		jump_from_wall_cling = true
	if jump_cancelled:
		if state_machine.get_jump_state() != state_machine.JumpState.DOUBLE_JUMP\
		and !double_jump_cancelled\
		and player.is_standard_ability_unlocked(player.StandardAbilities.HELICOPTER):
			state_machine.set_jump_state(state_machine.JumpState.DOUBLE_JUMP)
		else:
			return
	if state_machine.get_movement_state() == state_machine.MovementState.JUMPING and collisions.is_top_colliding():
		jump_cancelled = true
		return
	if state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP and collisions.is_top_colliding():
		double_jump_cancelled = true
		return
		
	if state_machine.get_movement_state() != state_machine.MovementState.JUMPING\
	or state_machine.get_action_state() == state_machine.ActionState.WALL_CLING\
	or state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP:
		if jump_from_wall_cling and !player_timers.get_jump_off_flag():
			player.velocity.x = JUMP_FORCE_FROM_WALL * -direction
			player_timers.set_jump_off_timer()
			player_timers.set_jump_off_flag(true)
			animated_sprite.flip_h = !animated_sprite.flip_h
		state_machine.set_movement_state(state_machine.MovementState.JUMPING)
		if state_machine.get_jump_state() != state_machine.JumpState.DOUBLE_JUMP:
			state_machine.set_jump_state(state_machine.JumpState.JUMP_START)
		jump_start_y = player.global_position.y
		if state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV:
			player.velocity.y = -JUMP_VELOCITY
		else:
			player.velocity.y = JUMP_VELOCITY

func handle_jump_helper(delta):
	#print(is_jump_height_reached())
	if Input.is_action_pressed("Jump")\
	and state_machine.get_movement_state() == state_machine.MovementState.JUMPING\
	and (!jump_cancelled or !double_jump_cancelled) \
	and !is_jump_height_reached():
		if state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV:
			player.velocity.y += JUMP_FORCE * delta
		else:
			player.velocity.y -= JUMP_FORCE * delta
	if Input.is_action_just_released("Jump"):
		jump_cancelled = true
		if state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP:
			double_jump_cancelled = true

func handle_falling(delta):
	if state_machine.get_rubber_band_state() == state_machine.RubberBandState.STICKY_BAND\
	or state_machine.get_transition_state() == state_machine.TransitionState.TRANSITIONING\
	or state_machine.get_movement_state() == state_machine.MovementState.DASH:
		return
	if not player.is_on_floor() and state_machine.get_action_state() != state_machine.ActionState.ZERO_GRAV:
		if state_machine.get_movement_state() != state_machine.MovementState.JUMPING and !jump_cancelled:
			#This means the player is falling without having jumped.
			state_machine.set_jump_state(state_machine.JumpState.JUMP_FALL_START)
			state_machine.set_movement_state(state_machine.MovementState.JUMPING)
		player.velocity.y += player.gravity * delta
		if state_machine.set_movement_state(state_machine.MovementState.JUMPING) and collisions.is_top_colliding():
			jump_cancelled = true
			if state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP:
				double_jump_cancelled = true
			state_machine.set_jump_state(state_machine.JumpState.JUMP_FALL_START)
	elif state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV:
		if not collisions.is_top_colliding():
			if state_machine.get_movement_state() != state_machine.MovementState.JUMPING and !jump_cancelled :
				state_machine.set_jump_state(state_machine.JumpState.JUMP_FALL_START)
				state_machine.set_movement_state(state_machine.MovementState.JUMPING)
			player.velocity.y -= player.gravity * delta
			if state_machine.get_movement_state() == state_machine.MovementState.JUMPING and collisions.is_bottom_colliding():
				jump_cancelled = true
		else:
			if state_machine.get_movement_state() != state_machine.MovementState.JUMPING:
				state_machine.set_jump_state(state_machine.JumpState.IDLE)
				jump_cancelled = false
	else:
		if state_machine.get_movement_state() != state_machine.MovementState.JUMPING:
			player_timers.set_zero_grav_cooldown_flag(false)
			state_machine.set_jump_state(state_machine.JumpState.IDLE)
			jump_cancelled = false
			double_jump_cancelled = false
			jump_from_wall_cling = false

func dash():
	if (state_machine.get_movement_state() == state_machine.MovementState.DASH or player.protein < DASH_PROTEIN_COST) and !player.god_mode:
		return
	state_machine.set_movement_state(state_machine.MovementState.DASH)
	if direction:
		player.velocity.x = DASH_VELOCITY * direction
	else:
		if !animated_sprite.flip_h:
			player.velocity.x = DASH_VELOCITY
		else:
			player.velocity.x = -DASH_VELOCITY
	player.velocity.y = 0
	if !player.god_mode:
		player.protein -= DASH_PROTEIN_COST
	emit_signal("protein_changed", player.protein)

func handle_sprint():
	if state_machine.get_movement_state() != state_machine.MovementState.JUMPING and collisions.is_bottom_colliding():
		state_machine.set_movement_state(state_machine.MovementState.SPRINTING)
		emit_signal("update_camera_follow_speed", SPRINT_SPEED)
		
func handle_stop_sprint():
	if state_machine.get_movement_state() == state_machine.MovementState.SPRINTING:
		if collisions.is_bottom_colliding():
			state_machine.set_movement_state(state_machine.MovementState.IDLE)
		else:
			state_machine.set_movement_state(state_machine.MovementState.JUMPING)
	emit_signal("update_camera_follow_speed", GROUND_SPEED)

func is_jump_height_reached():
	if jump_cancelled:
		if state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP:
			if double_jump_cancelled:
				return true
		else:
			return true
	if state_machine.get_action_state() != state_machine.ActionState.ZERO_GRAV:
		if player.global_position.y - jump_start_y <= -JUMP_CAP:
			if state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP:
				double_jump_cancelled = true
			jump_cancelled = true
			return true
		return false
	elif global_position.y - jump_start_y >= JUMP_CAP:
		if state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP:
			double_jump_cancelled = true
		jump_cancelled = true
		return true
	return false

func check_wall_cling():
	if player.is_on_wall():
		if state_machine.get_rubber_band_state() == state_machine.RubberBandState.STICKY_BAND:
			state_machine.set_rubber_band_state(state_machine.RubberBandState.IDLE)
		if state_machine.get_action_state() == state_machine.ActionState.RUBBER_BAND:
			state_machine.set_action_state(state_machine.ActionState.IDLE)
	else:
		jump_from_wall_cling = false
	if state_machine.get_action_state() == state_machine.ActionState.WALL_CLING:
		state_machine.set_action_state(state_machine.ActionState.IDLE)
		
	if (collisions.full_wall_contact_dir() == Directions.LEFT and Input.is_action_pressed("Left") and !jump_from_wall_cling)\
	or (collisions.full_wall_contact_dir() == Directions.RIGHT and Input.is_action_pressed("Right") and !jump_from_wall_cling):
		state_machine.set_action_state(state_machine.ActionState.WALL_CLING)
		player.velocity.y = 0

func auto_move_on_room_change(entrance_way):
	state_machine.set_transition_state(state_machine.TransitionState.TRANSITIONING)
	match entrance_way:
		RoomTransData.EntranceWay.TOP:
			state_machine.set_transition_state(state_machine.TransitionState.IDLE)
		RoomTransData.EntranceWay.BOTTOM:
			player.velocity.y = -JUMP_FORCE
			player.velocity.x = (SPRINT_SPEED) * direction
			await get_tree().create_timer(ROOM_ENTRANCE_AIR_TIME).timeout
			var timer = Timer.new()
			add_child(timer)
			timer.wait_time = ROOM_ENTRANCE_HORIZONTAL_TIME
			timer.one_shot = true
			timer.timeout.connect(_auto_move_helper)
			timer.start()
			player.velocity.y = 0
		RoomTransData.EntranceWay.LEFT:
			player.velocity.x = (GROUND_SPEED) * direction
			state_machine.set_movement_state(state_machine.MovementState.WALKING)
			await get_tree().create_timer(ROOM_ENTRANCE_HORIZONTAL_TIME).timeout
			player.velocity.x = 0
			state_machine.set_transition_state(state_machine.TransitionState.IDLE)
		RoomTransData.EntranceWay.RIGHT:
			player.velocity.x = (GROUND_SPEED) * direction
			state_machine.set_movement_state(state_machine.MovementState.WALKING)
			await get_tree().create_timer(ROOM_ENTRANCE_HORIZONTAL_TIME).timeout
			player.velocity.x = 0
			state_machine.set_transition_state(state_machine.TransitionState.IDLE)
		_:
			#"Why isn't this just outside the switch case so you don't have to repeat it for each case?"
			#Because the bottom case will switch the state too soon
			state_machine.set_transition_state(state_machine.TransitionState.IDLE)
			
func _auto_move_helper():
	player.velocity.x = 0
	state_machine.set_transition_state(state_machine.TransitionState.IDLE)

func get_direction():
	return direction
	
func set_direction(dir : float):
	direction = dir
	
func get_direction_lit():
	return direction_lit
	
func set_direction_lit(dir_lit : Directions):
	direction_lit = dir_lit
