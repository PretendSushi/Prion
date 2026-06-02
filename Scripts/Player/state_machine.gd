extends Node2D

#available states
enum TransitionState { IDLE, TRANSITIONING }
enum MovementState { IDLE, WALKING, DASH, SPRINTING, JUMPING }
enum ActionState { IDLE, ATTACK, RUBBER_BAND, DAMAGED, ZERO_GRAV, LEECH, WALL_CLING }
enum JumpState { IDLE, JUMP_START, JUMP_RISE, DOUBLE_JUMP, JUMP_FALL_START, JUMP_FALL, LANDING }
enum RubberBandState { IDLE, START, DURATION, STICKY_BAND, END}
enum LeechState { IDLE, START, DURATION, END }
#redundant, refers to all horizontal movement, in air and otherwise
enum WalkingState { IDLE, WALKING }

#state variables. Should be treated as private
var transition_state
var movement_state
var action_state
var jump_state
var rubber_band_state
var leech_state
var walking_state

func init():
	transition_state = TransitionState.IDLE
	movement_state = MovementState.IDLE
	action_state = ActionState.IDLE
	jump_state = JumpState.IDLE
	rubber_band_state = RubberBandState.IDLE
	leech_state = LeechState.IDLE
	walking_state = WalkingState.IDLE

func reset_jump():
	jump_state = JumpState.IDLE
	movement_state = MovementState.IDLE

func set_movement_state(state):
	if !MovementState.values().has(state):
		print("Error: Invalid movement state")
		return
	if movement_state == state:
		return
	movement_state = state
	
func get_movement_state():
	return movement_state
	
func set_transition_state(state):
	if !TransitionState.values().has(state):
		print("Error: Invalid transition state")
		return
	if transition_state == state:
		return
	transition_state = state
	
func get_transition_state():
	return transition_state
	
func set_action_state(state):
	if !ActionState.values().has(state):
		print("Error: Invalid action state")
		return
	if action_state == state:
		return
	action_state = state
	
func get_action_state():
	return action_state
	
func set_jump_state(state):
	if !JumpState.values().has(state):
		print("Error: Invalid jump state")
		return
	if jump_state == state:
		return
	jump_state = state
	
func get_jump_state():
	return jump_state
	
func set_rubber_band_state(state):
	if !RubberBandState.values().has(state):
		print("Error: Invalid rubber band state")
		return
	if rubber_band_state == state:
		return
	rubber_band_state = state
	
func get_rubber_band_state():
	return rubber_band_state
	
func set_leech_state(state):
	if !LeechState.values().has(state):
		print("Error: Invalid leech state")
		return
	if leech_state == state:
		return
	leech_state = state
	
func get_leech_state():
	return leech_state
	
func set_walking_state(state):
	if !WalkingState.values().has(state):
		print("Error: Invalid walking state")
		return
	if walking_state == state:
		return
	walking_state = state
	
func get_walking_state():
	return walking_state
