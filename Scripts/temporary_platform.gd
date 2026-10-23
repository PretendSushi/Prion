extends StaticBody2D

const STAND_TIMER = 0.5
const REGROW_TIMER = 5

var stand_time = 0
var regrow_time = 0

var is_stood_on := false
var is_broken := false

@onready var collision_shape = $CollisionShape2D
@onready var sprite = $Sprite2D

func _process(delta: float) -> void:
	if is_stood_on:
		handle_stand_timer(delta)
	elif is_broken:
		handle_regrow_timer(delta)
	else:
		reset_timers()
	
func handle_stand_timer(delta):
	if stand_time < STAND_TIMER:
		stand_time += delta
	else:
		break_plat()
		
func handle_regrow_timer(delta):
	if regrow_time < REGROW_TIMER:
		regrow_time += delta
	else:
		regrow_plat()
		
func break_plat():
	collision_shape.disabled = true
	is_broken = true
	sprite.visible = false
	
func regrow_plat():
	collision_shape.disabled = false
	is_broken = false
	sprite.visible = true

func reset_timers():
	stand_time = 0
	regrow_time = 0

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("Player"):
		is_stood_on = true
		
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body and body.is_in_group("Player"):
		is_stood_on = false
