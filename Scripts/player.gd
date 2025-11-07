extends CharacterBody2D

#signals
signal health_changed
signal initialize_health
signal player_attack
signal show_inventory
signal initialize_inventory

#constants
const GROUND_SPEED = 700.0
const AIR_SPEED = 900.0
const JUMP_VELOCITY = -800.0
const JUMP_FORCE = 2400.0
const BOUNCE_VELOCITY = -1200.0
const MAX_HEALTH = 100
const ATTACK_DAMAGE = 40
const RUBBER_BAND_DAMAGE = 80
const KNOCKBACK = 1000
const KNOCKBACK_DURATION = 0.5
const JUMP_CAP = 0.45
const V_KNOCKBACK = 150
const RB_ANIM_OFFSET = 450
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 1800#ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 0

#This fucker has caused me so much fucking grief but needs to exist, unfortunately.
#It tracks both the amount of pain it has caused me and
#whether the player has reached the apex of their jump or not
var apex_reached = false
#Tracks the amount of time the player has been knocked back
var knockback_timer = 0
var jump_timer = 0
#You know what this tracks
var health = 100
#This is a list of all lists the player has collected
var notes_list = []

#Available states
enum MovementState { IDLE, WALKING, JUMPING }
enum ActionState { IDLE, ATTACK, RUBBER_BAND }
enum JumpState { IDLE, JUMP_START, JUMP_RISE, JUMP_FALL_START, JUMP_FALL, LANDING }
enum RubberBandState { IDLE, START, DURATION, END}

#actual states
var movement_state = MovementState.IDLE
var action_state = ActionState.IDLE
var jump_state = JumpState.IDLE
var rubber_band_state = RubberBandState.IDLE

#Any children of the player that are needed in the code are here
@onready var animated_sprite = $AnimatedSprite2D
@onready var front_hitbox = $FrontHitbox
@onready var back_hitbox = $BackHitbox
@onready var bottom_hitbox = $BottomCollision
@onready var top_hitbox = $TopCollision
@onready var rb_hitbox_right = $RBCollisionRight
@onready var rb_hitbox_left = $RBCollisionLeft

func _ready():
	#initialize everything
	emit_signal("initialize_health", MAX_HEALTH, health)
	notes_list.append("Sample1")
	notes_list.append("Sample2")
	emit_signal("initialize_inventory", notes_list)
	animated_sprite.animation_finished.connect(_on_animation_finished) #calls _on_animation_finished every time an animation ends

func _physics_process(delta):
	#if the timer is over 0, the player is being knocked back
	if knockback_timer > 0:
		knockback_timer -= delta #Subtract elapsed time from it
		#once half the time has elapsed, the playaer needs to start falling
		if knockback_timer <= KNOCKBACK_DURATION / 2:
			velocity.y = V_KNOCKBACK 
	#if the player isn't being knocked back, they can move freely
	else:
		direction = move(delta,"")
	play_animations(direction)
	check_for_inputs()
	move_and_slide()

func check_for_inputs():
	#Movement inputs are not checked here
	#Check for attack input 
	if Input.is_action_just_pressed("Attack"):
		#This needs to be made more readable. Takes attack takes two arguments, whether up or down are being pressed
		attack(Input.is_action_pressed("Down"), Input.is_action_pressed("Jump"))
		#play animation for it (is this redundant?)
		play_animations(direction)
	#Check for open inventory input, and emit the signal so the inventory code can handle the rest
	if Input.is_action_just_pressed("Inventory"):
		emit_signal("show_inventory")
	if Input.is_action_just_pressed("RubberBand"):
		rubber_band()

func move(delta, action):
	var current_speed #it'll get a value, dw
	if not is_on_floor():
		#if the player didn't jump, but they're not on the floor, they're falling. Set that state for the animation
		if movement_state != MovementState.JUMPING:
			jump_state = JumpState.JUMP_FALL_START
		#boiler plate code. Makes guy fall :3
		velocity.y += gravity * delta
		action_state = ActionState.IDLE #this stops attacking from always being true if player attacks in the air. Will be changed later
		current_speed = AIR_SPEED #Should move faster in the air
	else:
		current_speed = GROUND_SPEED
	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor() and movement_state != MovementState.JUMPING:
		#Set states and velocity
		velocity.y = JUMP_VELOCITY
		jump_state = JumpState.JUMP_START
		movement_state = MovementState.JUMPING
		jump_timer = JUMP_CAP
	if Input.is_action_pressed("Jump") and movement_state == MovementState.JUMPING and velocity.y < 0 and jump_timer > 0:
		velocity.y -= JUMP_FORCE * delta
		jump_timer -= delta
	else:
		velocity.y += gravity * delta
	# Get the input direction and handle the movement/deceleration.
	#set states and speeds for left, right and idle
	if Input.is_action_pressed("Left") and action_state != ActionState.RUBBER_BAND:
		direction = -1.0
		if movement_state == MovementState.JUMPING:
			velocity.x = direction * AIR_SPEED
		else:
			velocity.x = direction * GROUND_SPEED
			movement_state = MovementState.WALKING
	elif Input.is_action_pressed("Right") and action_state != ActionState.RUBBER_BAND:
		direction = 1.0
		if movement_state == MovementState.JUMPING:
			velocity.x = direction * AIR_SPEED
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

func play_animations(direction):
	#Attack aniation shouldn't be interruptable
	if action_state == ActionState.ATTACK:
		return
		
	#this is the animation we will play at the end
	var target_anim = ""
	
	if is_on_floor():
		if movement_state == MovementState.JUMPING:
			if jump_state == JumpState.JUMP_START:
				target_anim = "jump_startup"
			else:
				target_anim = "jump_land"
		
		else:
			if action_state == ActionState.RUBBER_BAND:
				if rubber_band_state == RubberBandState.START:
					target_anim = "rubber_band_ground_startup"
				elif rubber_band_state == RubberBandState.DURATION:
					target_anim = "rubber_band_ground"
			elif movement_state == MovementState.WALKING:
				target_anim = "walk"
			else:
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
	
	if target_anim == "rubber_band_ground_startup" or target_anim == "rubber_band_ground":
		if direction >= 0:
			animated_sprite.offset.x = RB_ANIM_OFFSET
		else:
			animated_sprite.offset.x = -RB_ANIM_OFFSET
	else:
		animated_sprite.offset.x = 0
	#this is to avoid animations getting infinitely replayed and never ending
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)
		

func _on_enemy_hit_player(damage, knockback, enemy_pos):
	#TO FIX KNOCKBACK COMPARE ENEMY COORDS TO PLAYER COORDS
	health -= damage
	emit_signal("health_changed", health)
	var kb_dir = 0
	if enemy_pos.x < global_position.x:
		kb_dir = 1
	else:
		kb_dir = -1
	velocity.x = knockback * kb_dir
	velocity.y = -V_KNOCKBACK
	knockback_timer = KNOCKBACK_DURATION
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
	if action_state == ActionState.ATTACK:
		return
	#if it is a legit attack, set the state
	action_state = ActionState.ATTACK
	animated_sprite.play("attack") #and play the animation (probably redundant)
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
		if body.name == "Enemy":
			player_attack.connect(body._on_player_attack.bind())
			emit_signal("player_attack", ATTACK_DAMAGE, KNOCKBACK)
			if hitbox == bottom_hitbox:
				bounce()
	
func rubber_band():
	if action_state == ActionState.RUBBER_BAND:
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
		
func _on_health_pickup_picked_up():
	if health + 10 >= MAX_HEALTH:
		health = MAX_HEALTH
	elif health < MAX_HEALTH:
		health += 10
	emit_signal("health_changed", health)
