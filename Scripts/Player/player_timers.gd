extends Node2D

#Time limits
const KNOCKBACK_DURATION = 0.5
const INVINCIBLE_DURATION = 2.5
const JUMP_OFF_DURATION = 0.5
const ZERO_GRAV_DURATION = 3
const WALK_SFX_TIME = 0.3
const SPRINT_SFX_TIME = 0.1
const FALL_ANIM_SPEED_TIME = 1.0

#Values
const V_KNOCKBACK = 150

#Timers
var knockback_timer
var invincible_timer
var jump_off_timer
var zero_grav_timer
var walk_sfx_timer
var jump_fall_timer

#Flags
var invincible
var jump_off
var zero_grav_cooldown

var player
var state_machine
var animated_sprite

func init():
	knockback_timer = 0
	invincible_timer = 0
	jump_off_timer = 0
	zero_grav_timer = 0
	walk_sfx_timer = 0
	jump_fall_timer = 0
	invincible = false
	jump_off = false
	zero_grav_cooldown = false
	player = $".."
	state_machine = $"../StateMachine"
	animated_sprite = $"../AnimatedSprite2D"

func handle_knockback(delta):
	#if the timer is over 0, the player is being knocked back
	if knockback_timer > 0:
		knockback_timer -= delta #Subtract elapsed time from it
		#once half the time has elapsed, the playaer needs to start falling
		if knockback_timer <= KNOCKBACK_DURATION / 2:
			player.velocity.y = V_KNOCKBACK 
		return true
	return false

func handle_invincibility(delta):
	if invincible_timer > 0:
		invincible_timer -= delta
	else:
		invincible = false
		
func handle_jump_off(delta):
	if jump_off_timer > 0:
		jump_off_timer -= delta
	else:
		jump_off = false
		
func handle_zero_grav(delta):
	if zero_grav_timer > 0:
		zero_grav_timer -= delta
	else:
		if state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV:
			state_machine.set_action_state(state_machine.ActionState.IDLE)
			zero_grav_cooldown = true
			
func handle_fall_timer(delta):
	if state_machine.get_jump_state() != state_machine.JumpState.JUMP_FALL:
		animated_sprite.speed_scale = 1.0
		jump_fall_timer = 0
		return
	if jump_fall_timer >= FALL_ANIM_SPEED_TIME:
		animated_sprite.speed_scale = 3.0
		return
	if jump_fall_timer >= 0.5:
		animated_sprite.speed_scale = 2.0
	jump_fall_timer += delta
	
func handle_step_sfx_timer(delta):
	if walk_sfx_timer > 0:
		walk_sfx_timer -= delta
		return false
	if state_machine.get_movement_state() == state_machine.MovementState.WALKING:
		walk_sfx_timer = WALK_SFX_TIME
	elif state_machine.get_movement_state() == state_machine.MovementState.SPRINTING:
		walk_sfx_timer = SPRINT_SFX_TIME
	return true

func get_invincible_flag():
	return invincible

func set_invincible_flag(flag : bool):
	invincible = flag
	
func get_jump_off_flag():
	return jump_off
	
func set_jump_off_flag(flag : bool):
	jump_off = flag
	
func get_zero_grav_cooldown_flag():
	return zero_grav_cooldown
	
func set_zero_grav_cooldown_flag(flag : bool):
	zero_grav_cooldown = flag

func set_knockback_timer():
	knockback_timer = KNOCKBACK_DURATION
	
func set_invincible_timer():
	invincible_timer = INVINCIBLE_DURATION
	
func set_jump_off_timer():
	jump_off_timer = JUMP_OFF_DURATION
	
func set_zero_grav_timer():
	zero_grav_timer = ZERO_GRAV_DURATION
	
func set_walk_sfx_timer():
	walk_sfx_timer = WALK_SFX_TIME
