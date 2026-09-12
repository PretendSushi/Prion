extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer

const MAX_HEALTH = 1000
const MOVEMENT_SPEED = 500
const ATTACK_TIMER = 5
const ATTACK_ANIM_OFFSET = 250
const HIT_FLASH_TIMER = 0.2

enum ActionState { IDLE, MOVING, ATTACK }
enum AttackState { IDLE, START, DURATION, END }
enum Directions { NONE, LEFT, RIGHT }

var health

var direction
var action_state : ActionState
var attack_state : AttackState

var attack_timer
var hit_flash_timer

var can_attack : bool
var active : bool

func _ready() -> void:
	health = MAX_HEALTH
	attack_timer = ATTACK_TIMER
	hit_flash_timer = 0
	action_state = ActionState.IDLE
	attack_state = AttackState.IDLE
	active = false
	can_attack = true
	animated_sprite.material.set_shader_parameter("hit_flash_on", 0.0)

func _physics_process(delta: float) -> void:
	if active:
		var player_x = find_player_x()
		if player_x:
			move(player_x)
		handle_attack_timer(delta)
		handle_hit_flash_timer(delta)
		attack()
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
		direction = Directions.NONE
		action_state = ActionState.IDLE
		
func play_animations():
	var target_anim = "idle"
	if action_state == ActionState.MOVING:
		if direction == Directions.RIGHT:
			target_anim = "right"
		elif direction == Directions.LEFT:
			target_anim = "left"
	elif action_state == ActionState.IDLE:
		target_anim = "idle"
	elif action_state == ActionState.ATTACK:
		if attack_state == AttackState.START:
			target_anim = "attack_start"
		elif attack_state == AttackState.DURATION:
			target_anim = "attack"
		elif attack_state == AttackState.END:
			target_anim = "attack_end"
	
	if target_anim == "attack_start" or target_anim == "attack" or target_anim == "attack_end":
		animated_sprite.offset.y = ATTACK_ANIM_OFFSET
		animation_player.offset.y = ATTACK_ANIM_OFFSET
	else:
		animated_sprite.offset.y = 0
	animated_sprite.play(target_anim)
	animation_player.play(target_anim)
		

func attack():
	if action_state == ActionState.ATTACK or !can_attack:
		return
	action_state = ActionState.ATTACK
	attack_state = AttackState.START
	velocity.x = 0
	can_attack = false
	attack_timer = ATTACK_TIMER
	
func handle_attack_timer(delta):
	if attack_timer > 0:
		attack_timer -= delta
	else:
		can_attack = true

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


func _on_boss_trigger_activate_boss() -> void:
	active = true
	
func _on_player_attack(attack_dmg):
	animated_sprite.material.set_shader_parameter("hit_flash_on", 1.0)
	hit_flash_timer = HIT_FLASH_TIMER
	health -= attack_dmg

func die():
	queue_free()
