extends CharacterBody2D

signal hit_player
signal drop_health
signal drop_protein

const SPEED = 400.0
const JUMP_VELOCITY = -400.0
const KNOCKBACK_DURATION = 0.4
const KNOCKBACK = 700
const V_KNOCKBACK = 100

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
var protein_pickup = null
var knockback_timer = 0

@onready var detectBox = $DetectBox
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	health_pickup = preload("res://Scenes/HealthPickup.tscn")
	protein_pickup = preload("res://Scenes/ProteinPickup.tscn")
	player_in_range = false
	can_attack = true

func _physics_process(delta):
	#if the knockback timer isn't 0, that means knockback is still in effect. We don't want the enemy doing anything else
	if knockback_timer > 0:
		knockback_timer -= delta
	#if the knockback isn't in effect, the enemy can act as normal
	else:
		#reset the velocity to 0 since it was changed during knockback
		velocity.x = 0
		move(delta, direction)
	
		#checks if the player is in its detection range, then finds the direction
		var bodies = detectBox.get_overlapping_bodies()
		for body in bodies:
			find_player_direction(body)
		
		#handle the delay between attacks
		if not can_attack:
			time_since_last_attack += delta 
			if time_since_last_attack >= attack_cooldown:
				can_attack = true
				time_since_last_attack = 0.0
		if can_attack:
			attempt_hit_player(bodies)
			time_since_last_attack = 0.0
			can_attack = false
	
	#Move the enemy (will not move if velocity is 0 so this can run each frame)
	move_and_slide()
	
func move(delta, direction):
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	#Flip sprite
	animated_sprite.flip_h = velocity.x < 0


func _on_detect_box_body_entered(body):
	find_player_direction(body)

func _on_detect_box_body_exited(body: Node2D) -> void:
	direction = 0 
	
func find_player_direction(body):
	if body.name == "Player":
		if body.global_position.x - global_position.x < 0:
			direction = - 1
		else:
			direction = 1 
		player_in_range = true
		
func attempt_hit_player(bodies):
	if player_in_range:
		for body in bodies:
			if body.name == "Player":
				var distance_to_player = global_position.distance_to(body.global_position)
				if distance_to_player <= 300: #remove this magic number
					emit_signal("hit_player", damage, KNOCKBACK, global_position)
				break
				
func _on_player_attack(damage, knockback):
	health -= damage
	velocity.x = knockback * -direction
	velocity.y = -V_KNOCKBACK
	knockback_timer = KNOCKBACK_DURATION
	if health <= 0:
		die()
			
func die():
	emit_signal("drop_health", health_pickup, global_position.x, global_position.y)
	emit_signal("drop_protein", protein_pickup, global_position.x + 30, global_position.y) #magic number to be removed
	queue_free()
