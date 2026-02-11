extends CharacterBody2D

class_name Enemy

signal hit_player
signal drop_health
signal drop_protein

const JUMP_VELOCITY = -400.0
const KNOCKBACK_DURATION = 0.4
const FREEZE_DURATION = 1.0
const KNOCKBACK = 700
const V_KNOCKBACK = 100
const PROTEIN_PICKUP_OFFSET_X = 30
const PROTEIN_PICKUP_OFFSET_Y = 100
const PLAYER_ATTACK_MAX_DISTANCE = 300



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
var freeze_timer = 0
var can_move = true
var is_kbd = false
var speed = 400.0

@onready var detectBox = $DetectBox
@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $HitboxArea

func _ready():
	health_pickup = preload("res://Scenes/HealthPickup.tscn")
	protein_pickup = preload("res://Scenes/ProteinPickup.tscn")
	player_in_range = false
	can_attack = false

func _physics_process(delta):
	can_move = true
	is_kbd = handle_knockback(delta)
	#if the knockback isn't in effect, the enemy can act as normal
	can_move = handle_freeze(delta)
	
	if not is_on_floor():
		velocity.y += gravity * delta
	if can_move and !is_kbd:
		var player = find_player()
		attempt_hit_player(player)
		time_since_last_attack = 0.0
	move_and_slide()

	
func handle_knockback(delta):
	#if the knockback timer isn't 0, that means knockback is still in effect. We don't want the enemy doing anything else
	if knockback_timer > 0:
		knockback_timer -= delta
		return true
	if is_kbd:
		velocity.x = 0
	return false
		
func handle_freeze(delta):
	if freeze_timer > 0:
		freeze_timer -= delta
		return false
	return true
	
func move(delta, direction):
	#reset the velocity to 0 since it was changed during knockback
	velocity.x = 0

	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	#Flip sprite
	animated_sprite.flip_h = velocity.x < 0
	
func find_player_direction(body):
	if body.name == "Player":
		if body.global_position.x - global_position.x < 0:
			direction = - 1
		else:
			direction = 1 

func find_player():
	var bodies = detectBox.get_overlapping_bodies()
	for body in bodies:
		find_player_direction(body)
		if body.name == "Player":
			return body
			
func attempt_hit_player(body):
	if can_attack:
		emit_signal("hit_player", damage, KNOCKBACK, global_position)
				
func _on_player_attack(damage, knockback):
	health -= damage
	velocity.x = knockback * -direction
	velocity.y = -V_KNOCKBACK
	knockback_timer = KNOCKBACK_DURATION
	if health <= 0:
		die()

func _on_player_leech(damage):
	health -= damage
	freeze_timer = FREEZE_DURATION
	velocity.x = 0.0
	if health <= 0:
		die()

func die():
	emit_signal("drop_health", health_pickup, global_position.x, global_position.y - PROTEIN_PICKUP_OFFSET_Y)
	emit_signal("drop_protein", protein_pickup, global_position.x + PROTEIN_PICKUP_OFFSET_X, global_position.y - PROTEIN_PICKUP_OFFSET_Y)
	queue_free()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerHurtbox"):
		can_attack = true


func _on_hurtbox_area_exited(area: Area2D) -> void:
	if area.is_in_group("PlayerHurtbox"):
		can_attack = false
		
func is_body_player(body):
	return body.is_in_group("Player")
		
