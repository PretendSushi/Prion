extends CharacterBody2D

signal health_changed
signal initialize_health
signal player_attack
signal show_inventory
signal initialize_inventory

const GROUND_SPEED = 700.0
const AIR_SPEED = 900.0
const JUMP_VELOCITY = -1000.0
const BOUNCE_VELOCITY = -1200.0
const MAX_HEALTH = 100
const ATTACK_DAMAGE = 40
const KNOCKBACK = 1000
const KNOCKBACK_DURATION = 0.5
const V_KNOCKBACK = 150
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 0
var is_walking = false
var is_attacking = false
var is_jump_start = false
var is_jumping = false
var is_falling = false
var is_fall = false
var is_landing = false
var knockback_timer = 0

var health = 100

var notes_list = []

@onready var animated_sprite = $AnimatedSprite2D
@onready var front_hitbox = $FrontHitbox
@onready var back_hitbox = $BackHitbox
@onready var bottom_hitbox = $BottomCollision
@onready var top_hitbox = $TopCollision

func _ready():
	emit_signal("initialize_health", MAX_HEALTH, health)
	notes_list.append("Sample1")
	notes_list.append("Sample2")
	emit_signal("initialize_inventory", notes_list)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if knockback_timer > 0:
		knockback_timer -= delta
		if knockback_timer <= KNOCKBACK_DURATION / 2:
			velocity.y = V_KNOCKBACK
	else:
		direction = move(delta,"")
	play_animations(direction,false)
	check_for_inputs()
	move_and_slide()

func check_for_inputs():
	if Input.is_action_just_pressed("Attack"):
		attack(Input.is_action_pressed("Down"), Input.is_action_pressed("Jump"))
		play_animations(direction, true)
	if Input.is_action_just_pressed("Inventory"):
		emit_signal("show_inventory")

func move(delta, action):
	if not is_on_floor():
		velocity.y += gravity * delta
		is_attacking = false #this stops attacking from always being true if player attacks in the air. Will be changed later

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jump_start = true
	var current_speed = GROUND_SPEED
	if !is_on_floor():
		current_speed = AIR_SPEED
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.aaa
	if Input.is_action_pressed("Left"):
		direction = -1.0
		if not is_on_floor():
			velocity.x = direction * AIR_SPEED
		else:
			velocity.x = direction * GROUND_SPEED
		is_walking = true
	elif Input.is_action_pressed("Right"):
		direction = 1.0
		if not is_on_floor():
			velocity.x = direction * AIR_SPEED
		else:
			velocity.x = direction * GROUND_SPEED
		is_walking = true
	else:
		velocity.x = move_toward(velocity.x, 0, GROUND_SPEED)
		is_walking = false

	#Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	#move_and_slide()
	return direction
	
func play_animations(direction, attack):
	if is_attacking:
		return
		
	var target_anim = ""
	
	if is_on_floor():
		if is_jump_start:
			target_anim = "jump_startup"
		elif is_landing:
			target_anim = "jump_land"
		elif is_walking:
			target_anim = "walk"
		else:
			target_anim = "idle"
	else:
		if is_jump_start:
			target_anim = "jump_startup"
		elif is_jumping:
			target_anim = "jump_rise"
		elif is_fall:
			target_anim = "jump_fall"
		elif is_falling:
			target_anim = "jump_falling"
			
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)
		

func _on_enemy_hit_player(damage, knockback):
	health -= damage
	emit_signal("health_changed", health)
	velocity.x = knockback * -direction
	velocity.y = -V_KNOCKBACK
	knockback_timer = KNOCKBACK_DURATION
	if health <= 0:
		die()

func die():
	pass

func bounce():
	velocity.y = BOUNCE_VELOCITY

func attack(down_pressed, up_pressed):
	if is_attacking:
		return
	is_attacking = true
	animated_sprite.play("attack")
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
				
func _on_animation_finished():
	if animated_sprite.animation == "attack":
		is_attacking = false
	if animated_sprite.animation == "jump_startup":
		is_jump_start = false
		is_jumping = true
	if animated_sprite.animation == "jump_rise":
		is_jumping = false
		is_fall = true
	if animated_sprite.animation == "jump_fall":
		is_fall = false
		is_falling = true
	if animated_sprite.animation == "jump_falling":
		is_falling = false
		is_landing = true
	if animated_sprite.animation == "jump_land":
		is_landing = false
		#Reset all jumping flags
		is_jump_start = false
		is_jumping = false
		is_fall = false
		is_falling = false
		
func _on_health_pickup_picked_up():
	if health + 10 >= MAX_HEALTH:
		health = MAX_HEALTH
	elif health < MAX_HEALTH:
		health += 10
	emit_signal("health_changed", health)
