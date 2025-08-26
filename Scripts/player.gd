extends CharacterBody2D

signal health_changed
signal initialize_health

const SPEED = 700.0
const JUMP_VELOCITY = -700.0
const MAX_HEALTH = 100
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


var health = 100

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	emit_signal("initialize_health", MAX_HEALTH, health)

func _physics_process(delta):
	move(delta)
	
func move(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	#Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	#Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("walk")
	move_and_slide()

func _on_enemy_hit_player(damage):
	health -= damage
	emit_signal("health_changed", health)
