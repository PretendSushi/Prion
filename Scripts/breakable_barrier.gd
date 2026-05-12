extends Node2D

var health = 3

@onready var breakable_side = $BreakableSide

func _on_player_attack():
	var collider = breakable_side.get_collider()
	if collider and collider.is_in_group("Player"):
		health -= 1
		if health <= 0:
			breaks()
		
func breaks(): #couldn't name it break because break is a keyword :(
	queue_free()
