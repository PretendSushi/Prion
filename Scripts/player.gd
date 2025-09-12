extends CharacterBody2D

signal health_changed
signal initialize_health
signal player_attack

const GROUND_SPEED = 700.0
const AIR_SPEED = 900.0
const JUMP_VELOCITY = -1000.0
const BOUNCE_VELOCITY = -1200.0
const MAX_HEALTH = 100
const ATTACK_DAMAGE = 10
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 0



var health = 100

@onready var animated_sprite = $AnimatedSprite2D
@onready var front_hitbox = $FrontHitbox
@onready var back_hitbox = $BackHitbox
@onready var bottom_hitbox = $BottomCollision

func _ready():
	emit_signal("initialize_health", MAX_HEALTH, health)

func _physics_process(delta):
	direction = move(delta,"")
	play_animations(direction)
	check_for_inputs()

func check_for_inputs():
	if Input.is_action_just_pressed("Attack"):
		attack(Input.is_action_pressed("Down"))

func move(delta, action):
	if not is_on_floor():
		velocity.y += gravity * delta
		animated_sprite.play("idle")

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * GROUND_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, GROUND_SPEED)

	#Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	move_and_slide()
	return direction
	
func play_animations(direction):
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("walk")
	#Change speed when jumping
	else:
		if direction:
			velocity.x = direction * AIR_SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, AIR_SPEED)

func _on_enemy_hit_player(damage):
	health -= damage
	emit_signal("health_changed", health)

func bounce():
	velocity.y = BOUNCE_VELOCITY

func attack(down_pressed):
	#Decide which hitbox to use
	var hitbox = front_hitbox
	if direction == -1.0:
		hitbox = back_hitbox
	if not is_on_floor():
		if down_pressed:
			hitbox = bottom_hitbox
	#Find every NPC who should take damage
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.name == "Enemy":
			player_attack.connect(body._on_player_attack.bind())
			emit_signal("player_attack", ATTACK_DAMAGE)
			bounce()
		
	
		
