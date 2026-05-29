extends Node2D

#Modules
var movement

#Nodes
var raycast_top
var raycast_floor
var raycast_left_top
var raycast_left_mid
var raycast_left_bottom
var raycast_right_top
var raycast_right_mid
var raycast_right_bottom

var rb_hitbox_right
var rb_hitbox_left

var front_hitbox
var back_hitbox
var bottom_hitbox
var top_hitbox

var leech_right
var leech_left

func init():
	movement = $"../Movement"
	raycast_top = $"../RayCastTop"
	raycast_floor = $"../RayCastFloor"
	raycast_left_top = $"../RayCastLeftTop"
	raycast_left_mid = $"../RayCastLeftMiddle"
	raycast_left_bottom = $"../RayCastLeftBottom"
	raycast_right_top = $"../RayCastRightTop"
	raycast_right_mid = $"../RayCastRightMiddle"
	raycast_right_bottom = $"../RayCastRightBottom"
	
	rb_hitbox_left = $"../RBCollisionLeft"
	rb_hitbox_right = $"../RBCollisionRight"
	
	front_hitbox = $"../FrontHitbox"
	back_hitbox = $"../BackHitbox"
	bottom_hitbox = $"../BottomCollision"
	top_hitbox = $"../TopCollision"
	
	leech_left = $"../LeechCollisionLeft"
	leech_right = $"../LeechCollisionRight"
	
func is_on_surface():
	return raycast_floor.is_colliding() or raycast_top.is_colliding()
	
func is_top_colliding():
	return raycast_top.is_colliding()
	
func is_bottom_colliding():
	return raycast_floor.is_colliding()

func full_wall_contact_dir():
	if raycast_left_top.is_colliding()\
	and raycast_left_mid.is_colliding()\
	and raycast_left_bottom.is_colliding():
		return movement.Directions.LEFT
	
	if raycast_right_top.is_colliding()\
	and raycast_right_mid.is_colliding()\
	and raycast_right_bottom.is_colliding():
		return movement.Directions.RIGHT
	
	return null
	
func get_attack_hitbox():
	var hitbox = front_hitbox
	if movement.get_direction_lit() == movement.Directions.LEFT:
		hitbox = back_hitbox
	if not is_bottom_colliding():
		if Input.is_action_pressed("Down"):
			hitbox = bottom_hitbox
	if Input.is_action_pressed("Up"):
		hitbox = top_hitbox
	return hitbox
	
func get_rubber_band_hitbox():
	if movement.direction_lit == movement.Directions.RIGHT: 
		return rb_hitbox_right
	return rb_hitbox_left

func get_front_hitbox():
	return front_hitbox
	
func get_back_hitbox():
	return back_hitbox
	
func get_bottom_hitbox():
	return bottom_hitbox
	
func get_top_hitbox():
	return top_hitbox

func get_leech_left():
	return leech_left
	
func get_leech_right():
	return leech_right
