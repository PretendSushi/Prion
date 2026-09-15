extends CharacterBody2D

signal hit_player

@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer

const MAX_HEALTH = 1000
const MOVEMENT_SPEED = 1000
const ATTACK_TIMER = 5
const ATTACK_ANIM_OFFSET = 250
const HIT_FLASH_TIMER = 0.2
const DAMAGE = 20
const KNOCKBACK = 1000
const IDLE_TIME = 2

enum ActionState { IDLE, MOVING, ATTACK }
enum AttackState { IDLE, START, DURATION, END }
enum MovementState { IDLE, START, DURATION, END }
enum Directions { NONE, LEFT, RIGHT }
enum Phase { ONE, TWO, THREE }

var health
var curr_target

var direction
var action_state : ActionState
var attack_state : AttackState
var movement_state: MovementState

var attack_timer
var hit_flash_timer
var idle_timer

var can_attack : bool
var active : bool
var player_reached : bool

func _ready() -> void:
	health = MAX_HEALTH
	attack_timer = ATTACK_TIMER
	idle_timer = IDLE_TIME
	hit_flash_timer = 0
	action_state = ActionState.IDLE
	attack_state = AttackState.IDLE
	movement_state = MovementState.IDLE
	active = false
	can_attack = true
	player_reached = false
	animated_sprite.material.set_shader_parameter("hit_flash_on", 0.0)

func _physics_process(delta: float) -> void:
	if active:
		if curr_target and can_attack:
			move(curr_target)
		handle_idle_timer(delta)
		if curr_target and player_reached and movement_state == MovementState.IDLE:
			attack()
			idle_timer = IDLE_TIME
			curr_target = null
			player_reached = false
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
		if attack_state == AttackState.START:
			target_anim = "attack_start"
		elif attack_state == AttackState.DURATION:
			target_anim = "attack"
		elif attack_state == AttackState.END:
			target_anim = "attack_end"
	else:
		animated_sprite.offset.y = 0
	
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
	velocity.x = 0
	
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
		phase_one()

func handle_hit_flash_timer(delta):
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
	else:
		animated_sprite.material.set_shader_parameter("hit_flash_on", 0.0)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "attack_start":
		attack_state = AttackState.DURATION
	if animated_sprite.animation == "attack":
		attack_state = AttackState.END
	if animated_sprite.animation == "attack_end":
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

func phase_one():
	if !can_attack:
		return
	if !curr_target:
		curr_target = find_player_x()
	
