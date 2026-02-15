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
const MAX_HEALTH = 100
const MAX_PROTEIN = 100
const ATTACK_DAMAGE = 40
const RUBBER_BAND_DAMAGE = 80
const RUBBER_BAND_PROTEIN_COST = 40 
const KNOCKBACK = 1000
const KNOCKBACK_DURATION = 0.5
const INVINCIBLE_DURATION = 2.5
const JUMP_OFF_DURATION = 0.5
const ZERO_GRAV_DURATION = 3
const JUMP_CAP = 400 #max jump height in pixels
const V_KNOCKBACK = 150
const RB_ANIM_OFFSET = 450
const LEECH_ANIM_OFFSET = 100
const LEECH_HEALTH_GAIN = 25
const STICKY_BAND_SPEED = 1800
const JUMP_FORCE_FROM_WALL = 300
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 1800#ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 0

#This fucker has caused me so much fucking grief but needs to exist, unfortunately.
#It tracks both the amount of pain it has caused me and
#whether the player has reached the apex of their jump or not
var apex_reached = false
#Tracks the amount of time the player has been knocked back
var knockback_timer = 0
#var jump_timer = 0
var jump_start_y = 0
var jump_cancelled = false
#You know what this tracks
var health = 100
#Basically mana
var protein = 100
#This is a list of all lists the player has collected
var notes_list = []
#The current interactable object available to the player
var current_interactable = null
#Flag for invincibility
var invincible = false
#Timer for invincibility
var invincible_timer = 0
#Timer for zero g
var zero_grav_timer = 0
#cooldown check, sets to true when in effect
var zero_grav_cooldown = false
#flag to track if the player is trying to jump from a wall cling
var jump_from_wall_cling = false
#the player needs to jump off from the wall before being allowed to move freely
var jump_off_timer = 0
#this flag just tracks if the jump off is currently happening
var jump_off = false

#Available states
enum MovementState { IDLE, WALKING, SPRINTING, JUMPING }
enum ActionState { IDLE, ATTACK, RUBBER_BAND, DAMAGED, ZERO_GRAV, LEECH, WALL_CLING }
enum JumpState { IDLE, JUMP_START, JUMP_RISE, JUMP_FALL_START, JUMP_FALL, LANDING }
enum RubberBandState { IDLE, START, DURATION, STICKY_BAND, END}
enum LeechState { IDLE, START, DURATION, END }

#actual states
var movement_state = MovementState.IDLE
var action_state = ActionState.IDLE
var jump_state = JumpState.IDLE
var rubber_band_state = RubberBandState.IDLE
var leech_state = LeechState.IDLE

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
@onready var raycast_left = $RayCastLeft
@onready var raycast_right = $RayCastRight
@onready var hit_anim = $HitFlashAnim

func _ready():
	if RoomManager.player_stats != null:
		apply_data(RoomManager.player_stats)
	#initialize everything
	emit_signal("initialize_health", MAX_HEALTH, health)
	emit_signal("initialize_protein", MAX_PROTEIN, protein)
	emit_signal("initialize_inventory", notes_list)
	animated_sprite.animation_finished.connect(_on_animation_finished) #calls _on_animation_finished every time an animation ends

func _physics_process(delta):
	if !handle_knockback(delta):
		move(delta)
	handle_knockback(delta)
	handle_invincibility(delta)
	handle_zero_grav(delta)
	play_animations(direction)
	check_for_inputs(delta)
	handle_jump_helper(delta)
	handle_falling(delta)
	handle_jump_off(delta)
	check_wall_cling()
	move_and_slide()

func handle_knockback(delta):
	#if the timer is over 0, the player is being knocked back
	if knockback_timer > 0:
		knockback_timer -= delta #Subtract elapsed time from it
		#once half the time has elapsed, the playaer needs to start falling
		if knockback_timer <= KNOCKBACK_DURATION / 2:
			velocity.y = V_KNOCKBACK 
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
		if action_state == ActionState.ZERO_GRAV:
			action_state = ActionState.IDLE
			zero_grav_cooldown = true

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

func handle_jump(delta):
	if action_state == ActionState.WALL_CLING:
		jump_cancelled = false
		jump_from_wall_cling = true
	if jump_cancelled:
		return
	if movement_state == MovementState.JUMPING and is_top_colliding():
		jump_cancelled = true
		return
	if movement_state != MovementState.JUMPING or action_state == ActionState.WALL_CLING:
		if jump_from_wall_cling and !jump_off:
			velocity.x = JUMP_FORCE_FROM_WALL * -direction
			jump_off_timer = JUMP_OFF_DURATION
			jump_off = true
			animated_sprite.flip_h = !animated_sprite.flip_h
		movement_state = MovementState.JUMPING
		jump_state = JumpState.JUMP_START
		jump_start_y = global_position.y
		if action_state == ActionState.ZERO_GRAV:
			velocity.y = -JUMP_VELOCITY
		else:
			velocity.y = JUMP_VELOCITY

func handle_jump_helper(delta):
	if Input.is_action_pressed("Jump")\
	and movement_state == MovementState.JUMPING\
	and !jump_cancelled\
	and !is_jump_height_reached():
		if action_state == ActionState.ZERO_GRAV:
			velocity.y += JUMP_FORCE * delta
		else:
			velocity.y -= JUMP_FORCE * delta
	if Input.is_action_just_released("Jump"):
		jump_cancelled = true

func handle_falling(delta):
	if rubber_band_state == RubberBandState.STICKY_BAND:
		return
	if not is_on_floor() and action_state != ActionState.ZERO_GRAV:
		if movement_state != MovementState.JUMPING and !jump_cancelled:
			#This means the player is falling without having jumped.
			jump_state = JumpState.JUMP_FALL_START
			movement_state = MovementState.JUMPING
		velocity.y += gravity * delta
		if movement_state == MovementState.JUMPING and is_top_colliding():
			jump_cancelled = true
	elif action_state == ActionState.ZERO_GRAV:
		if not is_top_colliding():
			if movement_state != MovementState.JUMPING and !jump_cancelled:
				jump_state = JumpState.JUMP_FALL_START
				movement_state = MovementState.JUMPING
			velocity.y -= gravity * delta
			if movement_state == MovementState.JUMPING and is_bottom_colliding():
				jump_cancelled = true
		else:
			if movement_state != MovementState.JUMPING:
				jump_state = JumpState.IDLE
				jump_cancelled = false
	else:
		if movement_state != MovementState.JUMPING:
			zero_grav_cooldown = false
			jump_state = JumpState.IDLE
			jump_cancelled = false
			jump_from_wall_cling = false

func handle_sprint():
	if movement_state != MovementState.JUMPING and is_bottom_colliding():
		movement_state = MovementState.SPRINTING
		emit_signal("update_camera_follow_speed", SPRINT_SPEED)
		
func handle_stop_sprint():
	if movement_state == MovementState.SPRINTING:
		if is_bottom_colliding():
			movement_state = MovementState.IDLE
		else:
			movement_state = MovementState.JUMPING
		emit_signal("update_camera_follow_speed", GROUND_SPEED)

func move(delta):
	if rubber_band_state == RubberBandState.STICKY_BAND or jump_off:
		return
	if action_state != ActionState.RUBBER_BAND and action_state != ActionState.LEECH:
		if Input.is_action_pressed("Left"):
			direction = -1.0
			if movement_state == MovementState.JUMPING:
				velocity.x = direction * AIR_SPEED
			elif movement_state == MovementState.SPRINTING:
				velocity.x = direction * SPRINT_SPEED
			else:
				velocity.x = direction * GROUND_SPEED
				movement_state = MovementState.WALKING
		elif Input.is_action_pressed("Right"):
			direction = 1.0
			if movement_state == MovementState.JUMPING:
				velocity.x = direction * AIR_SPEED
			elif movement_state == MovementState.SPRINTING:
				velocity.x = direction * SPRINT_SPEED
			else:
				velocity.x = direction * GROUND_SPEED
				movement_state = MovementState.WALKING
		else:
			velocity.x = move_toward(velocity.x, 0, GROUND_SPEED)
			if movement_state != MovementState.JUMPING:
				movement_state = MovementState.IDLE

	#Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	return direction

func is_jump_height_reached():
	if jump_cancelled:
		return true
	if action_state != ActionState.ZERO_GRAV:
		if global_position.y - jump_start_y <= -JUMP_CAP:
			jump_cancelled = true
			return true
		return false
	elif global_position.y - jump_start_y >= JUMP_CAP:
		jump_cancelled = true
		return true
	return false
	
func is_on_surface():
	return raycast_floor.is_colliding() or raycast_top.is_colliding()
	
func is_top_colliding():
	return raycast_top.is_colliding()
	
func is_bottom_colliding():
	return raycast_floor.is_colliding()

func play_animations(direction):
	#this is the animation we will play at the end
	var target_anim = ""
	
	if is_on_surface():
		if action_state == ActionState.RUBBER_BAND:
			if rubber_band_state == RubberBandState.START:
				target_anim = "rubber_band_ground_startup"
			elif rubber_band_state == RubberBandState.DURATION:
				target_anim = "rubber_band_ground"
			elif rubber_band_state == RubberBandState.STICKY_BAND:
				target_anim = "sticky_band"
			else:
				target_anim = "idle"
		elif movement_state == MovementState.JUMPING:
			if jump_state == JumpState.JUMP_START:
				target_anim = "jump_startup"
			else:
				target_anim = "jump_land"
		else:
			if action_state == ActionState.LEECH:
				if leech_state == LeechState.START:
					target_anim = "leech_start"
				elif leech_state == LeechState.DURATION:
					target_anim = "leech"
				elif leech_state == LeechState.END:
					target_anim = "leech_end"
			elif action_state == ActionState.ATTACK:
				target_anim = "attack"
			elif movement_state == MovementState.WALKING:
				target_anim = "walk"
			elif movement_state == MovementState.SPRINTING:
				target_anim = "sprint"
			else:
				target_anim = "idle"
	else:
		if action_state == ActionState.RUBBER_BAND:
			if rubber_band_state == RubberBandState.START:
				target_anim = "rubber_band_ground_startup"
			elif rubber_band_state == RubberBandState.DURATION:
				target_anim = "rubber_band_ground"
			elif rubber_band_state == RubberBandState.STICKY_BAND:
				target_anim = "sticky_band"
		elif action_state == ActionState.WALL_CLING and !jump_from_wall_cling:
			target_anim = "idle"
		else:
			match jump_state:
				JumpState.JUMP_START:
					target_anim = "jump_startup"
				JumpState.JUMP_RISE:
					target_anim = "jump_rise"
				JumpState.JUMP_FALL_START:
					target_anim = "jump_fall"
				JumpState.JUMP_FALL:
					target_anim = "jump_falling"
				JumpState.IDLE:
					target_anim = "jump_fall"
	
	if action_state == ActionState.ZERO_GRAV:
		animated_sprite.flip_v = true
	else:
		animated_sprite.flip_v = false
		
	if target_anim == "rubber_band_ground_startup" or target_anim == "rubber_band_ground" or target_anim == "sticky_band":
		if direction >= 0:
			animated_sprite.offset.x = RB_ANIM_OFFSET
		else:
			animated_sprite.offset.x = -RB_ANIM_OFFSET
	elif target_anim == "leech_start" or target_anim == "leech" or target_anim == "leech_end":
		if direction >= 0:
			animated_sprite.offset.x = LEECH_ANIM_OFFSET
		else:
			animated_sprite.offset.x = -LEECH_ANIM_OFFSET
	else:
		animated_sprite.offset.x = 0
	#this is to avoid animations getting infinitely replayed and never ending
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)
		
func _on_enemy_hit_player(damage, knockback, enemy_pos):
	if invincible:
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
	velocity.y = -V_KNOCKBACK
	knockback_timer = KNOCKBACK_DURATION
	#handle invincibility
	invincible = true
	invincible_timer = INVINCIBLE_DURATION
	#handle cancelling rubberband
	if action_state == ActionState.RUBBER_BAND and rubber_band_state != RubberBandState.IDLE:
		action_state = ActionState.IDLE
		rubber_band_state = RubberBandState.IDLE
	#handle death
	if health <= 0:
		die()

func die():
	#TODO
	pass

func bounce():
	#for pogoing
	velocity.y = BOUNCE_VELOCITY

func attack(down_pressed, up_pressed):
	#the player can only attack once, then not again until the end of the animation
	if action_state == ActionState.ATTACK or action_state == ActionState.ZERO_GRAV:
		return
	#if it is a legit attack, set the state
	action_state = ActionState.ATTACK
	#Decide which hitbox to use
	var hitbox = front_hitbox
	if direction == -1.0:
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
	
func rubber_band():
	if action_state == ActionState.RUBBER_BAND or protein < RUBBER_BAND_PROTEIN_COST:
		return
	action_state = ActionState.RUBBER_BAND
	rubber_band_state = RubberBandState.START

func rubber_band_attack(direction):
	var hitbox = rb_hitbox_right
	if direction >= 0: 
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
	protein -= RUBBER_BAND_PROTEIN_COST
	emit_signal("protein_changed", protein)
	
func sticky_band(hitbox, body):
	rubber_band_state = RubberBandState.STICKY_BAND
	velocity.y = 0
	velocity.x = STICKY_BAND_SPEED * direction
	
func check_wall_cling():
	if is_on_wall():
		if rubber_band_state == RubberBandState.STICKY_BAND:
			rubber_band_state = RubberBandState.IDLE
		if action_state == ActionState.RUBBER_BAND:
			action_state = ActionState.IDLE
	else:
		jump_from_wall_cling = false
	if action_state == ActionState.WALL_CLING:
		action_state = ActionState.IDLE
		
	if (raycast_left.is_colliding() and Input.is_action_pressed("Left") and !jump_from_wall_cling)\
	or (raycast_right.is_colliding() and Input.is_action_pressed("Right") and !jump_from_wall_cling):
		action_state = ActionState.WALL_CLING
		velocity.y = 0

func zero_grav():
	if action_state == ActionState.ZERO_GRAV or zero_grav_cooldown:
		return
	action_state = ActionState.ZERO_GRAV
	zero_grav_timer = ZERO_GRAV_DURATION
	
func leech():
	if action_state == ActionState.LEECH:
		return
	action_state = ActionState.LEECH
	leech_state = LeechState.START

func is_leech_successful():
	var hitbox = leech_right
	if direction < 0:
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
		action_state = ActionState.IDLE
	if animated_sprite.animation == "jump_startup":
		jump_state = JumpState.JUMP_RISE
	if animated_sprite.animation == "jump_rise":
		#Since rising animation may need to be longer, the state doesn't change at the end of the animation
		#The player should have just started falling
		if velocity.y > 0 and !apex_reached:
			apex_reached = true#set apex_reached so this doesn't fire again
			jump_state = JumpState.JUMP_FALL_START
		else:
			animated_sprite.play("jump_rise") #if the player is still going up, replay the animation
	if animated_sprite.animation == "jump_fall":
		jump_state = JumpState.JUMP_FALL
	if animated_sprite.animation == "jump_falling":
		jump_state = JumpState.LANDING
	if animated_sprite.animation == "jump_land":
		jump_state = JumpState.IDLE
		movement_state = MovementState.IDLE
		apex_reached = false
	if animated_sprite.animation == "rubber_band_ground_startup":
		rubber_band_state = RubberBandState.DURATION
		rubber_band_attack(direction)
	if animated_sprite.animation == "rubber_band_ground":
		rubber_band_state = RubberBandState.IDLE
		action_state = ActionState.IDLE
	if animated_sprite.animation == "leech_start":
		if is_leech_successful():
			leech_state = LeechState.DURATION
		else:
			leech_state = LeechState.END
	if animated_sprite.animation == "leech":
		leech_state = LeechState.END
	if animated_sprite.animation == "leech_end":
		leech_state = LeechState.IDLE
		action_state = ActionState.IDLE

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
		"protein": protein
	}
	
func apply_data(data):
	health = data.health
	protein = data.protein
	
