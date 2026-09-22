extends CharacterBody2D

signal hit_player

@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var index_fing_left = $IndexLeft
@onready var mid_fing_left = $MidLeft
@onready var ring_fing_left = $RingLeft
@onready var pinky_fing_left = $PinkyLeft
@onready var index_fing_right = $IndexRight
@onready var mid_fing_right = $MidRight
@onready var ring_fing_right = $RingRight
@onready var pinky_fing_right = $PinkyRight
@onready var finger_scene: PackedScene = preload("res://Scenes/Bosses/Hand/Finger.tscn")

const MAX_HEALTH = 1000
const MOVEMENT_SPEED = 1000
const ATTACK_TIMER = 5
const ATTACK_ANIM_OFFSET = 250
const HIT_FLASH_TIMER = 0.2
const DAMAGE = 20
const KNOCKBACK = 1000
const IDLE_TIME = 2
const SLAP_MAX = 3
const SHOOT_MAX = 2
const SHOOT_FRAMES = [ 1, 3, 5, 7 ]

enum ActionState { IDLE, MOVING, ATTACK }
enum AttackState { IDLE, START, DURATION, END }
enum AvailableAttacks { SLAP, CLAP, SHOOT }
enum MovementState { IDLE, START, DURATION, END }
enum Directions { NONE, LEFT, RIGHT }
enum Phase { ONE, TWO, THREE }

var health
var curr_target

var direction : Directions
var action_state : ActionState
var attack_state : AttackState
var curr_attack : AvailableAttacks
var movement_state : MovementState
var phase : Phase

var attack_timer
var hit_flash_timer
var idle_timer

var can_attack : bool
var active : bool
var player_reached : bool
var slap_counter
var shot_counter

var left_shot_markers = [index_fing_left, mid_fing_left, ring_fing_left, pinky_fing_left]
var right_shot_markers = [index_fing_right, mid_fing_right, ring_fing_right, pinky_fing_right]

func _ready() -> void:
	health = MAX_HEALTH
	attack_timer = ATTACK_TIMER
	idle_timer = IDLE_TIME
	hit_flash_timer = 0
	action_state = ActionState.IDLE
	attack_state = AttackState.IDLE
	movement_state = MovementState.IDLE
	phase = Phase.THREE
	active = false
	can_attack = true
	player_reached = false
	slap_counter = 0
	shot_counter = 0
	animated_sprite.material.set_shader_parameter("hit_flash_on", 0.0)

func _physics_process(delta: float) -> void:
	if active:
		if phase == Phase.ONE:
			phase_one()
		if phase == Phase.TWO or phase == Phase.THREE:
			if phase == Phase.THREE and shot_counter < SHOOT_MAX:
				phase_three()
			elif slap_counter == SLAP_MAX:
				phase_two()
			else:
				phase_one()
		phase_two_helper()
		check_and_change_phase()
		handle_idle_timer(delta)
		handle_hit_flash_timer(delta)
		play_animations()
		move_and_slide()
	
func find_player_x():
	var player = get_tree().get_first_node_in_group("Player")
	if !player:
		return
	return player.global_position.x

func move(player_x):
	if action_state == ActionState.ATTACK:
		return
	if player_x + 10 > global_position.x and player_x - 10 > global_position.x:
		velocity.x = MOVEMENT_SPEED
		direction = Directions.RIGHT
		action_state = ActionState.MOVING
	elif player_x + 10 < global_position.x and player_x - 10 < global_position.x:
		velocity.x = -MOVEMENT_SPEED
		direction = Directions.LEFT
		action_state = ActionState.MOVING
	else:
		velocity.x = 0
		#direction = Directions.NONE
		action_state = ActionState.IDLE
		player_reached = true
		
	if action_state == ActionState.MOVING and movement_state == MovementState.IDLE:
		movement_state = MovementState.START
	if player_reached and movement_state != MovementState.IDLE:
		movement_state = MovementState.END
		
func play_animations():
	var target_anim = "idle"
	if movement_state != MovementState.IDLE:
		if direction == Directions.RIGHT:
			match movement_state:
				MovementState.START:
					target_anim = "right_start"
				MovementState.DURATION:
					target_anim = "right"
				MovementState.END:
					target_anim = "right_end"
		elif direction == Directions.LEFT:
			match movement_state:
				MovementState.START:
					target_anim = "left_start"
				MovementState.DURATION:
					target_anim = "left"
				MovementState.END:
					target_anim = "left_end"
	elif action_state == ActionState.IDLE:
		target_anim = "idle"
	elif action_state == ActionState.ATTACK:
		if curr_attack == AvailableAttacks.SLAP:
			if attack_state == AttackState.START:
				target_anim = "attack_slap_start"
			elif attack_state == AttackState.DURATION:
				target_anim = "attack_slap"
			elif attack_state == AttackState.END:
				target_anim = "attack_slap_end"
		elif curr_attack == AvailableAttacks.CLAP:
			if attack_state == AttackState.START:
				target_anim = "attack_clap_start"
			elif attack_state == AttackState.DURATION:
				target_anim = "attack_clap"
			elif attack_state == AttackState.END:
				target_anim = "attack_clap_end"
		elif curr_attack == AvailableAttacks.SHOOT:
			if attack_state == AttackState.START:
				target_anim = "attack_shoot_start"
			elif attack_state == AttackState.DURATION:
				target_anim = "attack_shoot"
			elif attack_state == AttackState.END:
				target_anim = "attack_shoot_end"

	if action_state == ActionState.ATTACK and direction == Directions.RIGHT:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
		
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)
		animation_player.play(target_anim)
		
func attack():
	if action_state == ActionState.ATTACK:
		return
	action_state = ActionState.ATTACK
	attack_state = AttackState.START
	movement_state = MovementState.IDLE
	velocity.x = 0
	if curr_attack == AvailableAttacks.SLAP:
		slap_counter += 1
	if curr_attack == AvailableAttacks.CLAP:
		slap_counter = 0
		shot_counter = 0
	if  curr_attack == AvailableAttacks.SHOOT:
		shot_counter += 1
	
func handle_attack_timer(delta):
	if attack_timer > 0:
		attack_timer -= delta
	else:
		can_attack = true

func handle_idle_timer(delta):
	if attack_state != AttackState.IDLE:
		return
	if idle_timer > 0:
		idle_timer -= delta
		action_state = ActionState.IDLE
	else:
		can_attack = true

func handle_hit_flash_timer(delta):
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
	else:
		animated_sprite.material.set_shader_parameter("hit_flash_on", 0.0)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "attack_slap_start" or animated_sprite.animation == "attack_clap_start" or animated_sprite.animation == "attack_shoot_start":
		attack_state = AttackState.DURATION
	if animated_sprite.animation == "attack_slap" or animated_sprite.animation == "attack_clap" or animated_sprite.animation == "attack_shoot":
		attack_state = AttackState.END
	if animated_sprite.animation == "attack_slap_end" or animated_sprite.animation == "attack_clap_end" or animated_sprite.animation == "attack_shoot_end":
		attack_state = AttackState.IDLE
		action_state = ActionState.IDLE
	if animated_sprite.animation == "left_start" or animated_sprite.animation == "right_start":
		movement_state = MovementState.DURATION
	if animated_sprite.animation == "left_end" or animated_sprite.animation == "right_end":
		movement_state = MovementState.IDLE

func _on_boss_trigger_activate_boss() -> void:
	active = true
	
func _on_player_attack(attack_dmg):
	animated_sprite.material.set_shader_parameter("hit_flash_on", 1.0)
	hit_flash_timer = HIT_FLASH_TIMER
	health -= attack_dmg

func die():
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		emit_signal("hit_player", DAMAGE, KNOCKBACK, global_position)

func check_and_change_phase():
	if health <= (MAX_HEALTH / Phase.size()) * 2:
		phase = Phase.TWO
	if health <= (MAX_HEALTH / Phase.size()):
		phase = Phase.THREE

func phase_one():
	if !can_attack:
		return
	curr_attack = AvailableAttacks.SLAP
	if !curr_target:
		curr_target = find_player_x()
	move(curr_target)
	if curr_target and player_reached and movement_state == MovementState.IDLE:
		attack()
		idle_timer = IDLE_TIME
		curr_target = null
		player_reached = false
		can_attack = false

func phase_two():
	if !can_attack:
		return
	curr_attack = AvailableAttacks.CLAP
	if !curr_target:
		curr_target = find_player_x()
	velocity.x = 0
	attack()
	idle_timer = IDLE_TIME
	can_attack = false

func phase_two_helper():
	if curr_attack == AvailableAttacks.CLAP:
		if attack_state == AttackState.DURATION:
			global_position.x = curr_target
			
func phase_three():
	if phase != Phase.THREE or !can_attack:
		return
	curr_attack = AvailableAttacks.SHOOT
	curr_target = find_player_x()
	if curr_target <= global_position.x:
		direction = Directions.LEFT
	else:
		direction = Directions.RIGHT
	velocity.x = 0
	attack()
	idle_timer = IDLE_TIME
	can_attack = false
	
func phase_three_helper():
	if curr_attack == AvailableAttacks.SHOOT and attack_state == AttackState.DURATION:
		for i in range(SHOOT_FRAMES.size()):
			if animated_sprite.frame == SHOOT_FRAMES[i]:
				match i:
					0:
						if direction == Directions.LEFT:
							spawn_finger(index_fing_left)
						else:
							spawn_finger(index_fing_right)
					1:
						if direction == Directions.LEFT:
							spawn_finger(mid_fing_left)
						else:
							spawn_finger(mid_fing_right)
					2:
						if direction == Directions.LEFT:
							spawn_finger(ring_fing_left)
						else:
							spawn_finger(ring_fing_right)
					3:
						if direction == Directions.LEFT:
							spawn_finger(pinky_fing_left)
						else:
							spawn_finger(pinky_fing_right)
							

func spawn_finger(marker):
	var finger = finger_scene.instantiate()
	add_child(finger)
	finger.global_position = marker.global_position

func _on_animated_sprite_frame_changed() -> void:
	phase_three_helper()
