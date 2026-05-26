extends Node2D

#Constants
const RB_ANIM_OFFSET = 450
const LEECH_ANIM_OFFSET = 100
const WALL_CLING_ANIM_OFFSET = 17

#Modules
var animated_sprite
var state_machine
var movement
var collisions
var attacks
var player

func init():
	animated_sprite = $"../AnimatedSprite2D"
	state_machine = $"../StateMachine"
	movement = $"../Movement"
	collisions = $"../Collisions"
	attacks = $"../Attacks"
	player = $".."
	animated_sprite.animation_finished.connect(_on_animation_finished) #calls _on_animation_finished every time an animation ends

func play_animations():
	#this is the animation we will play at the end
	var target_anim = ""
	
	if collisions.is_on_surface():
		if state_machine.get_action_state() == state_machine.ActionState.RUBBER_BAND:
			if state_machine.get_rubber_band_state() == state_machine.RubberBandState.START:
				target_anim = "rubber_band_ground_startup"
			elif state_machine.get_rubber_band_state() == state_machine.RubberBandState.DURATION:
				target_anim = "rubber_band_ground"
			elif state_machine.get_rubber_band_state() == state_machine.RubberBandState.STICKY_BAND:
				target_anim = "sticky_band"
			else:
				target_anim = "idle"
		elif state_machine.get_movement_state() == state_machine.MovementState.JUMPING:
			if state_machine.get_jump_state() == state_machine.JumpState.JUMP_START:
				target_anim = "jump_startup"
			else:
				if state_machine.get_walking_state() == state_machine.WalkingState.IDLE:
					target_anim = "jump_land"
				else:
					target_anim = "walk"
					state_machine.reset_jump()
		elif state_machine.get_movement_state() == state_machine.MovementState.DASH:
			target_anim = "dash"
		else:
			if state_machine.get_action_state() == state_machine.ActionState.LEECH:
				if state_machine.get_leech_state() == state_machine.LeechState.START:
					target_anim = "leech_start"
				elif state_machine.get_leech_state() == state_machine.LeechState.DURATION:
					target_anim = "leech"
				elif state_machine.get_leech_state() == state_machine.LeechState.END:
					target_anim = "leech_end"
			elif state_machine.get_action_state() == state_machine.ActionState.ATTACK:
				target_anim = "attack"
			elif state_machine.get_movement_state() == state_machine.MovementState.WALKING:
				target_anim = "walk"
			elif state_machine.get_movement_state() == state_machine.MovementState.SPRINTING:
				target_anim = "sprint"
			else:
				target_anim = "idle"
	else:
		if state_machine.get_action_state() == state_machine.ActionState.RUBBER_BAND:
			if state_machine.get_rubber_band_state() == state_machine.RubberBandState.START:
				target_anim = "rubber_band_ground_startup"
			elif state_machine.get_rubber_band_state() == state_machine.RubberBandState.DURATION:
				target_anim = "rubber_band_ground"
			elif state_machine.get_rubber_band_state() == state_machine.RubberBandState.STICKY_BAND:
				target_anim = "sticky_band"
		elif state_machine.get_action_state() == state_machine.ActionState.WALL_CLING and !movement.jump_from_wall_cling:
			target_anim = "wall_cling"
		elif state_machine.get_movement_state() == state_machine.MovementState.DASH:
			target_anim = "dash"
		else:
			match state_machine.get_jump_state():
				state_machine.JumpState.JUMP_START:
					target_anim = "jump_startup"
				state_machine.JumpState.JUMP_RISE:
					if state_machine.get_walking_state() == state_machine.WalkingState.IDLE:
						target_anim = "jump_rise"
					else:
						target_anim = "jump_rise_fwd"
				state_machine.JumpState.DOUBLE_JUMP:
					target_anim = "double_jump"
				state_machine.JumpState.JUMP_FALL_START:
					target_anim = "jump_fall"
				state_machine.JumpState.JUMP_FALL:
					target_anim = "jump_falling"
				state_machine.JumpState.IDLE:
					target_anim = "jump_fall"
	
	if state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV:
		animated_sprite.flip_v = true
	else:
		animated_sprite.flip_v = false
		
	if target_anim == "rubber_band_ground_startup" or target_anim == "rubber_band_ground" or target_anim == "sticky_band":
		if movement.get_direction_lit() == movement.Directions.RIGHT:
			animated_sprite.offset.x = RB_ANIM_OFFSET
		else:
			animated_sprite.offset.x = -RB_ANIM_OFFSET
	elif target_anim == "leech_start" or target_anim == "leech" or target_anim == "leech_end":
		if movement.get_direction_lit() == movement.Directions.RIGHT:
			animated_sprite.offset.x = LEECH_ANIM_OFFSET
		else:
			animated_sprite.offset.x = -LEECH_ANIM_OFFSET
	elif target_anim == "wall_cling":
		if movement.get_direction_lit() == movement.Directions.LEFT:
			animated_sprite.offset.x = WALL_CLING_ANIM_OFFSET
		else:
			animated_sprite.offset.x = -WALL_CLING_ANIM_OFFSET
	else:
		animated_sprite.offset.x = 0
	#this is to avoid animations getting infinitely replayed and never ending
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)

func _on_animation_finished():
	#changes state at the end of animations. Exists for animation purposes
	if animated_sprite.animation == "attack":
		state_machine.set_action_state(state_machine.ActionState.IDLE)
	if animated_sprite.animation == "jump_startup":
		state_machine.set_jump_state(state_machine.JumpState.JUMP_RISE)
	if animated_sprite.animation == "jump_rise"\
	or animated_sprite.animation == "double_jump"\
	or animated_sprite.animation == "jump_rise_fwd":
		#Since rising animation may need to be longer, the state doesn't change at the end of the animation
		#The player should have just started falling
		if player.velocity.y > 0:
			state_machine.set_jump_state(state_machine.JumpState.JUMP_FALL_START)
		else:
			if animated_sprite.animation == "jump_rise":
				animated_sprite.play("jump_rise") #if the player is still going up, replay the animation
			elif animated_sprite.animation == "jump_rise_fwd":
				animated_sprite.play("jump_rise_fwd")
			else:
				animated_sprite.play("double_jump")
	if animated_sprite.animation == "jump_fall":
		state_machine.set_jump_state(state_machine.JumpState.JUMP_FALL)
	if animated_sprite.animation == "jump_land":
		player.play_sounds(player.SoundEffects.WALK)
		state_machine.set_jump_state(state_machine.JumpState.IDLE)
		state_machine.set_movement_state(state_machine.MovementState.IDLE)
	if animated_sprite.animation == "rubber_band_ground_startup":
		state_machine.set_rubber_band_state(state_machine.RubberBandState.DURATION)
		attacks.rubber_band_attack()
	if animated_sprite.animation == "rubber_band_ground":
		state_machine.set_rubber_band_state(state_machine.RubberBandState.IDLE)
		state_machine.set_action_state(state_machine.ActionState.IDLE)
	if animated_sprite.animation == "leech_start":
		if player.is_leech_successful():
			state_machine.set_leech_state(state_machine.LeechState.DURATION)
		else:
			state_machine.set_leech_state(state_machine.LeechState.END)
	if animated_sprite.animation == "leech":
		state_machine.set_leech_state(state_machine.LeechState.END)
	if animated_sprite.animation == "leech_end":
		state_machine.set_leech_state(state_machine.LeechState.IDLE)
		state_machine.set_action_state(state_machine.ActionState.IDLE)
	if animated_sprite.animation == "dash":
		state_machine.set_movement_state(state_machine.MovementState.JUMPING)
		state_machine.set_jump_state(state_machine.JumpState.JUMP_FALL_START)
		movement.jump_cancelled = true
		player.velocity.x = 0
