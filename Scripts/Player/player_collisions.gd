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
