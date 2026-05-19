extends CharacterBody2D

#signals
signal health_changed
signal protein_changed
signal initialize_health
signal initialize_protein
signal player_attack
signal player_leech
signal show_inventory
signal initialize_inventory
signal interacted
signal note_added
signal update_camera
signal update_camera_follow_speed

#constants
const GROUND_SPEED = 700.0
const AIR_SPEED = 900.0
const SPRINT_SPEED = 1400.0
const JUMP_VELOCITY = -800.0
const JUMP_FORCE = 3000
const BOUNCE_VELOCITY = -1200.0
const DASH_VELOCITY = 1500
const MAX_HEALTH = 100
const MAX_PROTEIN = 100
const ATTACK_DAMAGE = 40
const RUBBER_BAND_DAMAGE = 80
const RUBBER_BAND_PROTEIN_COST = 40 
const DASH_PROTEIN_COST = 5
const KNOCKBACK = 1000
const ROOM_ENTRANCE_AIR_TIME = 0.05
const ROOM_ENTRANCE_HORIZONTAL_TIME = 0.2
const JUMP_CAP = 400 #max jump height in pixels
const RB_ANIM_OFFSET = 450
const LEECH_ANIM_OFFSET = 100
const WALL_CLING_ANIM_OFFSET = 17
const LEECH_HEALTH_GAIN = 25
const STICKY_BAND_SPEED = 1800
const JUMP_FORCE_FROM_WALL = 300
const STEP_PITCH_LOW = 0.80
const STEP_PITCH_HIGH = 1.20
#Paths for sound effects
const STEP_SFX_PATH = "res://Assets/Sounds/Player/Step.wav"

#variables for sound effects
var step_sfx

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 1800#ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 0

#Tracks the amount of time the player has been knocked back
var jump_start_y = 0
var jump_cancelled = false
var double_jump_cancelled = false
#You know what this tracks
var health = 100
#Basically mana
var protein = 100
#This is a list of all notes the player has collected
var notes_list = []
#A list of abilities the player has unlocked
var unlocked_standard_abilities = []
#The current interactable object available to the player
var current_interactable = null
#flag to track if the player is trying to jump from a wall cling
var jump_from_wall_cling = false

#debug tool
var god_mode = false

#Available abilities
enum StandardAbilities { LIQUIFY, RUBBER_BAND, STICKY_BAND, HELICOPTER, ZERO_GRAV }
#Sound effects
enum SoundEffects { WALK }
#Direction
enum Directions { LEFT, RIGHT }

#actual direction
var direction_lit = Directions.RIGHT

#Any children of the player that are needed in the code are here
@onready var animated_sprite = $AnimatedSprite2D
@onready var front_hitbox = $FrontHitbox
@onready var back_hitbox = $BackHitbox
@onready var bottom_hitbox = $BottomCollision
@onready var top_hitbox = $TopCollision
@onready var rb_hitbox_right = $RBCollisionRight
@onready var rb_hitbox_left = $RBCollisionLeft
@onready var leech_right = $LeechCollisionRight
@onready var leech_left = $LeechCollisionLeft
@onready var raycast_floor = $RayCastFloor
@onready var raycast_top = $RayCastTop

@onready var raycast_left_top = $RayCastLeftTop
@onready var raycast_left_mid = $RayCastLeftMiddle
@onready var raycast_left_bottom = $RayCastLeftBottom

@onready var raycast_right_top = $RayCastRightTop
@onready var raycast_right_mid = $RayCastRightMiddle
@onready var raycast_right_bottom = $RayCastRightBottom

@onready var hit_anim = $HitFlashAnim
@onready var audio_player = $AudioPlayer

@onready var state_machine = $StateMachine
@onready var player_timers = $Timers

func _ready():
	state_machine.init()
	player_timers.init()
	if RoomManager.player_stats != null:
		apply_data(RoomManager.player_stats)
		flip_for_direction()
	if health <= 0:
		restore_max_hp()
		hit_anim.stop()
		hit_anim.seek(0, true)
		animated_sprite.material.set_shader_parameter("hit_flash_on", 0.0)
	#initialize everything
	emit_signal("initialize_health", MAX_HEALTH, health)
	emit_signal("initialize_protein", MAX_PROTEIN, protein)
	emit_signal("initialize_inventory", notes_list)
	animated_sprite.animation_finished.connect(_on_animation_finished) #calls _on_animation_finished every time an animation ends
	unlocked_standard_abilities.append(StandardAbilities.HELICOPTER)
	unlocked_standard_abilities.append(StandardAbilities.RUBBER_BAND)
	unlocked_standard_abilities.append(StandardAbilities.STICKY_BAND)
	unlocked_standard_abilities.append(StandardAbilities.ZERO_GRAV)
	
	step_sfx = load(STEP_SFX_PATH)
	audio_player.stream = step_sfx
	audio_player.max_distance = 5000

func _physics_process(delta):
	if !player_timers.handle_knockback(delta):
		move(delta)
	player_timers.handle_knockback(delta)
	player_timers.handle_invincibility(delta)
	player_timers.handle_zero_grav(delta)
	play_animations()
	check_for_inputs(delta)
	handle_jump_helper(delta)
	handle_falling(delta)
	player_timers.handle_jump_off(delta)
	check_wall_cling()
	player_timers.handle_fall_timer(delta)
	move_and_slide()

func check_for_inputs(delta):
	#Movement inputs are not checked here
	#Check for attack input 
	if Input.is_action_just_pressed("Attack"):
		#This needs to be made more readable. Takes attack takes two arguments, whether up or down are being pressed
		attack(Input.is_action_pressed("Down"), Input.is_action_pressed("Jump"))
	#Check for open inventory input, and emit the signal so the inventory code can handle the rest
	if Input.is_action_just_pressed("Inventory"):
		emit_signal("show_inventory")
	if Input.is_action_just_pressed("RubberBand"):
		rubber_band()
	if Input.is_action_just_pressed("Interact"):
		interact()
	if Input.is_action_just_pressed("ZeroGrav"):
		zero_grav()
	if Input.is_action_just_pressed("Leech"):
		leech()
	if Input.is_action_just_pressed("Jump"):
		handle_jump(delta)
	if Input.is_action_pressed("Sprint"):
		handle_sprint()
	if Input.is_action_just_released("Sprint"):
		handle_stop_sprint()
	if Input.is_action_just_pressed("Dash"):
		dash()

func handle_jump(delta):
	if state_machine.get_action_state() == state_machine.ActionState.WALL_CLING:
		jump_cancelled = false
		jump_from_wall_cling = true
	if jump_cancelled:
		if state_machine.get_jump_state() != state_machine.JumpState.DOUBLE_JUMP\
		and !double_jump_cancelled\
		and is_standard_ability_unlocked(StandardAbilities.HELICOPTER):
			state_machine.set_jump_state(state_machine.JumpState.DOUBLE_JUMP)
		else:
			return
	if state_machine.get_movement_state() == state_machine.MovementState.JUMPING and is_top_colliding():
		jump_cancelled = true
		return
	if state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP and is_top_colliding():
		double_jump_cancelled = true
		return
		
	if state_machine.get_movement_state() != state_machine.MovementState.JUMPING\
	or state_machine.get_action_state() == state_machine.ActionState.WALL_CLING\
	or state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP:
		if jump_from_wall_cling and !player_timers.get_jump_off_flag():
			velocity.x = JUMP_FORCE_FROM_WALL * -direction
			player_timers.set_jump_off_timer()
			player_timers.set_jump_off_flag(true)
			animated_sprite.flip_h = !animated_sprite.flip_h
		state_machine.set_movement_state(state_machine.MovementState.JUMPING)
		if state_machine.get_jump_state() != state_machine.JumpState.DOUBLE_JUMP:
			state_machine.set_jump_state(state_machine.JumpState.JUMP_START)
		jump_start_y = global_position.y
		if state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV:
			velocity.y = -JUMP_VELOCITY
		else:
			velocity.y = JUMP_VELOCITY

func handle_jump_helper(delta):
	#print(is_jump_height_reached())
	if Input.is_action_pressed("Jump")\
	and state_machine.get_movement_state() == state_machine.MovementState.JUMPING\
	and (!jump_cancelled or !double_jump_cancelled) \
	and !is_jump_height_reached():
		if state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV:
			velocity.y += JUMP_FORCE * delta
		else:
			velocity.y -= JUMP_FORCE * delta
	if Input.is_action_just_released("Jump"):
		jump_cancelled = true
		if state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP:
			double_jump_cancelled = true

func handle_falling(delta):
	if state_machine.get_rubber_band_state() == state_machine.RubberBandState.STICKY_BAND\
	or state_machine.get_transition_state() == state_machine.TransitionState.TRANSITIONING\
	or state_machine.get_movement_state() == state_machine.MovementState.DASH:
		return
	if not is_on_floor() and state_machine.get_action_state() != state_machine.ActionState.ZERO_GRAV:
		if state_machine.get_movement_state() != state_machine.MovementState.JUMPING and !jump_cancelled:
			#This means the player is falling without having jumped.
			state_machine.set_jump_state(state_machine.JumpState.JUMP_FALL_START)
			state_machine.set_movement_state(state_machine.MovementState.JUMPING)
		velocity.y += gravity * delta
		if state_machine.set_movement_state(state_machine.MovementState.JUMPING) and is_top_colliding():
			jump_cancelled = true
			if state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP:
				double_jump_cancelled = true
			state_machine.set_jump_state(state_machine.JumpState.JUMP_FALL_START)
	elif state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV:
		if not is_top_colliding():
			if state_machine.get_movement_state() != state_machine.MovementState.JUMPING and !jump_cancelled :
				state_machine.set_jump_state(state_machine.JumpState.JUMP_FALL_START)
				state_machine.set_movement_state(state_machine.MovementState.JUMPING)
			velocity.y -= gravity * delta
			if state_machine.get_movement_state() == state_machine.MovementState.JUMPING and is_bottom_colliding():
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
	if (state_machine.get_movement_state() == state_machine.MovementState.DASH or protein < DASH_PROTEIN_COST) and !god_mode:
		return
	state_machine.set_movement_state(state_machine.MovementState.DASH)
	if direction:
		velocity.x = DASH_VELOCITY * direction
	else:
		if !animated_sprite.flip_h:
			velocity.x = DASH_VELOCITY
		else:
			velocity.x = -DASH_VELOCITY
	velocity.y = 0
	if !god_mode:
		protein -= DASH_PROTEIN_COST
	emit_signal("protein_changed", protein)

func handle_sprint():
	if state_machine.get_movement_state() != state_machine.MovementState.JUMPING and is_bottom_colliding():
		state_machine.set_movement_state(state_machine.MovementState.SPRINTING)
		emit_signal("update_camera_follow_speed", SPRINT_SPEED)
		
func handle_stop_sprint():
	if state_machine.get_movement_state() == state_machine.MovementState.SPRINTING:
		if is_bottom_colliding():
			state_machine.set_movement_state(state_machine.MovementState.IDLE)
		else:
			state_machine.set_movement_state(state_machine.MovementState.JUMPING)
	emit_signal("update_camera_follow_speed", GROUND_SPEED)

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
				play_sounds(SoundEffects.WALK)
			state_machine.set_walking_state(state_machine.WalkingState.WALKING)
		elif Input.is_action_pressed("Right"):
			direction = 1.0
			direction_lit = Directions.RIGHT
			if state_machine.get_movement_state() != state_machine.MovementState.JUMPING\
			and player_timers.handle_step_sfx_timer(delta):
				play_sounds(SoundEffects.WALK)
			state_machine.set_walking_state(state_machine.WalkingState.WALKING)
			
		if state_machine.get_movement_state() == state_machine.MovementState.JUMPING:
			velocity.x = direction * AIR_SPEED
		elif state_machine.get_movement_state() == state_machine.MovementState.SPRINTING:
			velocity.x = direction * SPRINT_SPEED
		else:
			velocity.x = direction * GROUND_SPEED
			state_machine.set_movement_state(state_machine.MovementState.WALKING)
		
		if !Input.is_action_pressed("Left") and !Input.is_action_pressed("Right"):
			velocity.x = 0
			if state_machine.get_movement_state() != state_machine.MovementState.JUMPING:
				state_machine.set_movement_state(state_machine.MovementState.IDLE)
			state_machine.set_walking_state(state_machine.WalkingState.IDLE)

	#Flip sprite
	if direction_lit == Directions.RIGHT:
		animated_sprite.flip_h = false
	elif direction_lit == Directions.LEFT:
		animated_sprite.flip_h = true

func is_jump_height_reached():
	if jump_cancelled:
		if state_machine.get_jump_state() == state_machine.JumpState.DOUBLE_JUMP:
			if double_jump_cancelled:
				return true
		else:
			return true
	if state_machine.get_action_state() != state_machine.ActionState.ZERO_GRAV:
		if global_position.y - jump_start_y <= -JUMP_CAP:
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
	
func is_on_surface():
	return raycast_floor.is_colliding() or raycast_top.is_colliding()
	
func is_top_colliding():
	return raycast_top.is_colliding()
	
func is_bottom_colliding():
	return raycast_floor.is_colliding()

func play_animations():
	#this is the animation we will play at the end
	var target_anim = ""
	
	if is_on_surface():
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
					reset_jump()
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
		elif state_machine.get_action_state() == state_machine.ActionState.WALL_CLING and !jump_from_wall_cling:
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
		if direction_lit == Directions.RIGHT:
			animated_sprite.offset.x = RB_ANIM_OFFSET
		else:
			animated_sprite.offset.x = -RB_ANIM_OFFSET
	elif target_anim == "leech_start" or target_anim == "leech" or target_anim == "leech_end":
		if direction_lit == Directions.RIGHT:
			animated_sprite.offset.x = LEECH_ANIM_OFFSET
		else:
			animated_sprite.offset.x = -LEECH_ANIM_OFFSET
	elif target_anim == "wall_cling":
		if direction_lit == Directions.LEFT:
			animated_sprite.offset.x = WALL_CLING_ANIM_OFFSET
		else:
			animated_sprite.offset.x = -WALL_CLING_ANIM_OFFSET
	else:
		animated_sprite.offset.x = 0
	#this is to avoid animations getting infinitely replayed and never ending
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)
		
func _on_enemy_hit_player(damage, knockback, enemy_pos):
	if player_timers.get_invincible_flag() or god_mode:
		return
	hit_anim.play("hit")
	health -= damage
	emit_signal("health_changed", health)
	#handle knockback
	var kb_dir = 0
	if enemy_pos.x < global_position.x:
		kb_dir = 1
	else:
		kb_dir = -1
	velocity.x = knockback * kb_dir
	velocity.y = -player_timers.V_KNOCKBACK
	player_timers.set_knockback_timer()
	#handle invincibility
	player_timers.set_invincible_flag(true)
	player_timers.set_invincible_timer()
	#handle cancelling rubberband
	if state_machine.get_action_state() == state_machine.ActionState.RUBBER_BAND and state_machine.get_rubber_band_state() != state_machine.RubberBandState.IDLE:
		state_machine.set_action_state(state_machine.ActionState.IDLE)
		state_machine.set_rubber_band_state(state_machine.RubberBandState.IDLE)
	#handle death
	if health <= 0:
		die()

func die():
	if god_mode:
		return
	if !RoomManager.last_save_point:
		print("Error, no save point found")
		return
	if RoomManager.last_save_point.room_id != RoomManager.get_room_data().room_id:
		#RoomManager.get_room_path_by_id(RoomManager.last_save_point.room_id)
		RoomManager.change_level(RoomManager.last_save_point)
	else:
		global_position.x = RoomManager.last_save_point.player_x
		global_position.y = RoomManager.last_save_point.player_y
	CustomStatTracker.add_death()

func bounce():
	#for pogoing
	velocity.y = BOUNCE_VELOCITY

func attack(down_pressed, up_pressed):
	#the player can only attack once, then not again until the end of the animation
	if state_machine.get_action_state() == state_machine.ActionState.ATTACK or state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV:
		return
	#if it is a legit attack, set the state
	state_machine.set_action_state(state_machine.ActionState.ATTACK)
	#Decide which hitbox to use
	var hitbox = front_hitbox
	if direction_lit == Directions.LEFT:
		hitbox = back_hitbox
	if not is_on_floor():
		if down_pressed:
			hitbox = bottom_hitbox
	if up_pressed:
		hitbox = top_hitbox
	#Find every NPC who should take damage
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.name.contains("Enemy"):
			player_attack.connect(body._on_player_attack.bind())
			emit_signal("player_attack", ATTACK_DAMAGE, KNOCKBACK)
			if hitbox == bottom_hitbox:
				bounce()
		if body.is_in_group("Barrier"):
			player_attack.connect(body._on_player_attack.bind())
			emit_signal("player_attack")
	
func rubber_band():
	if state_machine.get_action_state() == state_machine.ActionState.RUBBER_BAND\
	or protein < RUBBER_BAND_PROTEIN_COST\
	or !is_standard_ability_unlocked(StandardAbilities.RUBBER_BAND):
		return
	state_machine.set_action_state(state_machine.ActionState.RUBBER_BAND)
	state_machine.set_rubber_band_state(state_machine.RubberBandState.START)

func rubber_band_attack():
	var hitbox = rb_hitbox_right
	if direction_lit == Directions.RIGHT: 
		hitbox = rb_hitbox_right
	else:
		hitbox = rb_hitbox_left
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.name == "Enemy":
			player_attack.connect(body._on_player_attack.bind())
			emit_signal("player_attack", RUBBER_BAND_DAMAGE, KNOCKBACK)
		if body.name == "TileMap":
			sticky_band(hitbox, body)
	if !god_mode:
		protein -= RUBBER_BAND_PROTEIN_COST
		emit_signal("protein_changed", protein)
	
func sticky_band(hitbox, body):
	if !is_standard_ability_unlocked(StandardAbilities.STICKY_BAND) and !god_mode:
		return
	state_machine.set_rubber_band_state(state_machine.RubberBandState.STICKY_BAND)
	velocity.y = 0
	velocity.x = STICKY_BAND_SPEED * direction
	
func check_wall_cling():
	if is_on_wall():
		if state_machine.get_rubber_band_state() == state_machine.RubberBandState.STICKY_BAND:
			state_machine.set_rubber_band_state(state_machine.RubberBandState.IDLE)
		if state_machine.get_action_state() == state_machine.ActionState.RUBBER_BAND:
			state_machine.set_action_state(state_machine.ActionState.IDLE)
	else:
		jump_from_wall_cling = false
	if state_machine.get_action_state() == state_machine.ActionState.WALL_CLING:
		state_machine.set_action_state(state_machine.ActionState.IDLE)
		
	if (full_wall_contact_dir() == Directions.LEFT and Input.is_action_pressed("Left") and !jump_from_wall_cling)\
	or (full_wall_contact_dir() == Directions.RIGHT and Input.is_action_pressed("Right") and !jump_from_wall_cling):
		state_machine.set_action_state(state_machine.ActionState.WALL_CLING)
		velocity.y = 0
		
func full_wall_contact_dir():
	if raycast_left_top.is_colliding()\
	and raycast_left_mid.is_colliding()\
	and raycast_left_bottom.is_colliding():
		return Directions.LEFT
	
	if raycast_right_top.is_colliding()\
	and raycast_right_mid.is_colliding()\
	and raycast_right_bottom.is_colliding():
		return Directions.RIGHT
	
	return null

func zero_grav():
	if state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV\
	or player_timers.get_zero_grav_cooldown_flag()\
	or !is_standard_ability_unlocked(StandardAbilities.ZERO_GRAV):
		return
	state_machine.set_action_state(state_machine.ActionState.ZERO_GRAV)
	player_timers.set_zero_grav_timer()
	
func leech():
	if state_machine.get_action_state() == state_machine.ActionState.LEECH:
		return
	state_machine.set_action_state(state_machine.ActionState.LEECH)
	state_machine.set_leech_state(state_machine.LeechState.START)

func is_leech_successful():
	var hitbox = leech_right
	if direction_lit == Directions.LEFT:
		hitbox = leech_left
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Enemy"):
			player_leech.connect(body._on_player_leech.bind())
			emit_signal("player_leech", ATTACK_DAMAGE)
			on_leech_successful()
			return true
	return false

func on_leech_successful():
	if health + LEECH_HEALTH_GAIN >= 100:
		health = 100
	else:
		health += LEECH_HEALTH_GAIN
	emit_signal("health_changed", health)

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
		if velocity.y > 0:
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
		play_sounds(SoundEffects.WALK)
		state_machine.set_jump_state(state_machine.JumpState.IDLE)
		state_machine.set_movement_state(state_machine.MovementState.IDLE)
	if animated_sprite.animation == "rubber_band_ground_startup":
		state_machine.set_rubber_band_state(state_machine.RubberBandState.DURATION)
		rubber_band_attack()
	if animated_sprite.animation == "rubber_band_ground":
		state_machine.set_rubber_band_state(state_machine.RubberBandState.IDLE)
		state_machine.set_action_state(state_machine.ActionState.IDLE)
	if animated_sprite.animation == "leech_start":
		if is_leech_successful():
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
		jump_cancelled = true
		velocity.x = 0

func _on_interactable_focused(interactable) -> void:
	current_interactable = interactable

func _on_interactable_unfocused(interactable) -> void:
	if current_interactable == interactable:
		current_interactable = null
		
func _on_pickupable_picked_up(pickupable, value) -> void:
	if pickupable.name == "HealthPickup":
		handle_health_pickup(value)
	if pickupable.name == "ProteinPickup":
		handle_protein_pickup(value)

func handle_health_pickup(health_gain):
	if health + health_gain >= MAX_HEALTH:
		health = MAX_HEALTH
	elif health < MAX_HEALTH:
		health += health_gain
	emit_signal("health_changed", health)
	
func handle_protein_pickup(protein_gain):
	if protein + protein_gain >= MAX_PROTEIN:
		protein = MAX_PROTEIN
	elif protein < MAX_PROTEIN:
		protein += protein_gain
	emit_signal("protein_changed", protein)
	
func interact():
	if current_interactable == null:
		return
	interacted.connect(current_interactable._on_interact.bind())
	emit_signal("interacted", self)

func restore_max_hp():
	health = MAX_HEALTH
	emit_signal("health_changed", health)
	
func add_note(note_name):
	notes_list.append(note_name)
	emit_signal("note_added", note_name)
	
func get_data_as_dict():
	return {
		"health": health,
		"protein": protein,
		"direction": direction,
		"direction_lit": direction_lit
	}
	
func apply_data(data):
	health = data.health
	protein = data.protein
	direction = data.direction
	direction_lit = data.direction_lit
	
func auto_move_on_room_change(entrance_way):
	state_machine.set_transition_state(state_machine.TransitionState.TRANSITIONING)
	match entrance_way:
		RoomTransData.EntranceWay.TOP:
			state_machine.set_transition_state(state_machine.TransitionState.IDLE)
		RoomTransData.EntranceWay.BOTTOM:
			velocity.y = -JUMP_FORCE
			velocity.x = (SPRINT_SPEED) * direction
			await get_tree().create_timer(ROOM_ENTRANCE_AIR_TIME).timeout
			var timer = Timer.new()
			add_child(timer)
			timer.wait_time = ROOM_ENTRANCE_HORIZONTAL_TIME
			timer.one_shot = true
			timer.timeout.connect(_auto_move_helper)
			timer.start()
			velocity.y = 0
		RoomTransData.EntranceWay.LEFT:
			velocity.x = (GROUND_SPEED) * direction
			state_machine.set_movement_state(state_machine.MovementState.WALKING)
			await get_tree().create_timer(ROOM_ENTRANCE_HORIZONTAL_TIME).timeout
			velocity.x = 0
			state_machine.set_transition_state(state_machine.TransitionState.IDLE)
		RoomTransData.EntranceWay.RIGHT:
			velocity.x = (GROUND_SPEED) * direction
			state_machine.set_movement_state(state_machine.MovementState.WALKING)
			await get_tree().create_timer(ROOM_ENTRANCE_HORIZONTAL_TIME).timeout
			velocity.x = 0
			state_machine.set_transition_state(state_machine.TransitionState.IDLE)
		_:
			#"Why isn't this just outside the switch case so you don't have to repeat it for each case?"
			#Because the bottom case will switch the state too soon
			state_machine.set_transition_state(state_machine.TransitionState.IDLE)
			
func _auto_move_helper():
	velocity.x = 0
	state_machine.set_transition_state(state_machine.TransitionState.IDLE)

func is_standard_ability_unlocked(target_ability: StandardAbilities):
	if god_mode:
		return true
	for ability in unlocked_standard_abilities:
		if ability == target_ability:
			return true
	return false

func play_sounds(sound_effect: SoundEffects):
	if sound_effect == SoundEffects.WALK:
		if !audio_player.playing:
			audio_player.pitch_scale = randf_range(STEP_PITCH_LOW, STEP_PITCH_HIGH) 
			audio_player.play()

func set_last_save_point(save_dict: Dictionary):
	if not save_dict:
		print("Error. No data")
		return
	RoomManager.set_last_save_point(save_dict)

func activate_god_mode():
	god_mode = true
	
func deactivate_god_mode():
	god_mode = false

func flip_for_direction():
	if direction_lit == Directions.LEFT:
		direction = -1.0
		animated_sprite.flip_h = true
	elif direction_lit == Directions.RIGHT:
		direction = 1.0
		animated_sprite.flip_h = false
		
func reset_jump():
	state_machine.set_jump_state(state_machine.JumpState.IDLE)
	state_machine.set_movement_state(state_machine.MovementState.IDLE)
	
func get_data_to_save():
	return {
		"last_save_point": RoomManager.last_save_point,
		"unlocked_abilities": unlocked_standard_abilities
	}
 
func apply_save_data(data):
	set_last_save_point(data["last_save_point"])
	unlocked_standard_abilities = data["unlocked_abilities"]
	global_position.x = data["last_save_point"]["player_x"]
	global_position.y = data["last_save_point"]["player_y"]
