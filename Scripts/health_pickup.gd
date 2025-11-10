extends Node2D

signal picked_up

@onready var area2d = $Area2D
@onready var floor_ray = $RayCast2D

var gravity = 1800
var velocity := Vector2.ZERO
var is_on_floor = false

func _ready():
	pass
	
func _physics_process(delta: float) -> void:
	is_on_floor = floor_ray.is_colliding()
	
	if is_on_floor:
		velocity.y = 0
	else:
		velocity.y = gravity * delta
	print(velocity.y)
	position += velocity

func _on_detect_box_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		emit_signal("picked_up")
		queue_free()
