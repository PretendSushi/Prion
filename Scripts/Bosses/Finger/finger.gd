extends CharacterBody2D

const SPEED = 100

enum Direction { LEFT, RIGHT }

var direction

@onready var animated_sprite = $AnimatedSprite2D

var collided: bool

func _ready() -> void:
	direction = Direction.LEFT
	collided = false

func _physics_process(delta: float) -> void:
	move()
	play_animations()
	move_and_slide()
	
func move():
	if !collided:
		if direction == Direction.LEFT:
			velocity.x -= SPEED
		else:
			velocity.x += SPEED
	else:
		velocity.x = 0

func set_direction(dir: Direction):
	direction = dir

func play_animations():
	var target_anim = "fly"
	if !collided:
		target_anim = "fly"
	else:
		target_anim = "splat"
		
	if animated_sprite.animation != target_anim:
		animated_sprite.play(target_anim)
		
func _on_hitbox_body_entered(body: Node2D) -> void:
	get_parent()._on_hitbox_body_entered(body)
	collided = true
	
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "splat":
		queue_free()
