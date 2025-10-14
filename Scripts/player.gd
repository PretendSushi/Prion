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
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 0
var is_walking = false
var is_attacking = false

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
	direction = move(delta,"")
	play_animations(direction,false)
	check_for_inputs()

func check_for_inputs():
	if Input.is_action_just_pressed("Attack"):
		attack(Input.is_action_pressed("Down"), Input.is_action_pressed("Jump"))
		play_animations(direction, true)
	if Input.is_action_just_pressed("Inventory"):
		emit_signal("show_inventory")

func move(delta, action):
	if not is_on_floor():
		velocity.y += gravity * delta
		animated_sprite.play("idle")

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	#var current_speed = is_on_floor() ? GROUND_SPEED : AIR_SPEED
	var current_speed = GROUND_SPEED
	if !is_on_floor():
		current_speed = AIR_SPEED
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.aaa
	if Input.is_action_pressed("Left"):
		direction = -1.0
		velocity.x = direction * GROUND_SPEED
		is_walking = true
	elif Input.is_action_pressed("Right"):
		direction = 1.0
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

	move_and_slide()
	return direction
	
func play_animations(direction, attack):
	if is_attacking:
		return
	if is_on_floor():
		if is_walking:
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")

func _on_enemy_hit_player(damage):
	print("hit2")
	health -= damage
	emit_signal("health_changed", health)
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
			emit_signal("player_attack", ATTACK_DAMAGE)
			if hitbox == bottom_hitbox:
				bounce()
				
func _on_animation_finished():
	if animated_sprite.animation == "attack":
		is_attacking = false
		
func _on_health_pickup_picked_up():
	health += 10
	emit_signal("health_changed", health)
