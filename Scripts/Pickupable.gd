extends Node2D

class_name Pickupable

signal picked_up

@onready var area2d = $Area2D
@onready var floor_ray = $RayCast2D

var gravity = 1800
var velocity := Vector2.ZERO
var is_on_floor = false

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	is_on_floor = floor_ray.is_colliding()
	
	if is_on_floor:
		velocity.y = 0
	else:
		velocity.y = gravity * delta

	position += velocity
	
func _on_detect_box_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		picked_up.connect(body._on_pickupable_picked_up.bind())
		emit_signal("picked_up", self)
		queue_free()
