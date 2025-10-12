extends CharacterBody2D

signal hit_player
signal drop_health

const SPEED = 400.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 0
var player_in_range
var damage = 25
var time_since_last_attack = 0.0
var attack_cooldown = 2
var can_attack
var health = 100
var health_pickup = null

@onready var detectBox = $DetectBox
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	health_pickup = preload("res://Scenes/HealthPickup.tscn")
	player_in_range = false
	can_attack = true

func _physics_process(delta):
	move(delta, direction)
	
	var bodies = detectBox.get_overlapping_bodies()
	for body in bodies:
		find_player_direction(body)
	
	if not can_attack:
		time_since_last_attack += delta
		if time_since_last_attack >= attack_cooldown:
			can_attack = true
			time_since_last_attack = 0.0
	if can_attack:
		attempt_hit_player(bodies)
		time_since_last_attack = 0.0
		can_attack = false
	
func move(delta, direction):
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if direction:
		velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	#Flip sprite
	animated_sprite.flip_h = velocity.x < 0

	move_and_slide()

func _on_detect_box_body_entered(body):
	find_player_direction(body)

func _on_detect_box_body_exited(body: Node2D) -> void:
	direction = 0
	
func find_player_direction(body):
	if body.name == "Player":
		direction = (body.global_position - global_position).normalized()
		player_in_range = true
		
func attempt_hit_player(bodies):
	if player_in_range:
		for body in bodies:
			if body.name == "Player":
				var distance_to_player = global_position.distance_to(body.global_position)
				if distance_to_player <= 300:
					emit_signal("hit_player", damage)
				break
				
func _on_player_attack(damage):
	health -= damage
	if health <= 0:
		die()
			
func die():
	
	emit_signal("drop_health", health_pickup, global_position.x, global_position.y)
	queue_free()
