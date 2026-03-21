extends Camera2D

@onready var tilemap: TileMap = $"../TileMap"
@onready var player: CharacterBody2D = $"../Player"

@export var horizontal_deadzone = 30
@export var vertical_deadzone = 30
@export var follow_speed = 700.0

var boss_trigger_entered = false
var zoom_speed = 2.0
var target_zoom = Vector2(0.5, 0.5)

func _ready():
	setup_camera_limits()
	
func _physics_process(delta: float) -> void:
	update_camera_position(delta)
	if zoom != target_zoom:
		zoom = zoom.lerp(target_zoom, zoom_speed * delta)

func setup_camera_limits():
	global_position = player.global_position
	var used_rect = tilemap.get_used_rect()
	var cell_size = tilemap.tile_set.tile_size
	var map_width = used_rect.size.x * cell_size.x
	var map_height = used_rect.size.y * cell_size.y
	
	limit_left = used_rect.position.x * cell_size.x
	limit_right = limit_left + map_width
	limit_top = used_rect.position.y * cell_size.y
	limit_bottom = limit_top + map_height
	
func update_camera_position(delta):
	if not player:
		return
	
	var player_pos = player.global_position
	var camera_pos = global_position
	var viewport_size = get_viewport_rect().size / zoom
	var target_pos = camera_pos
	
	if abs(player_pos.x - camera_pos.x) > horizontal_deadzone:
		target_pos.x = player_pos.x
		
	if player_pos.y < camera_pos.y - vertical_deadzone:
		target_pos.y = player_pos.y
	elif player_pos.y > camera_pos.y + vertical_deadzone:
		target_pos.y = player_pos.y
		
	position.x = move_toward(position.x, target_pos.x, follow_speed * delta)
	
	if player_pos.y > camera_pos.y:
		position.y = move_toward(position.y, target_pos.y, player.velocity.y * delta)
	else:
		position.y = move_toward(position.y, target_pos.y, follow_speed * delta)


func _on_player_update_camera_follow_speed(speed) -> void:
	follow_speed = speed


func _on_boss_trigger_boss_camera(left_bound, right_bound) -> void:
	if boss_trigger_entered:
		return
	
	boss_trigger_entered = true
	limit_left = left_bound
	limit_right = right_bound
	
	var bound_width = (right_bound - left_bound) / get_viewport_rect().size.x
	
	target_zoom = zoom / (bound_width/ 2)
	


func _on_boss_detrigger_deboss_camera() -> void:
	if !boss_trigger_entered:
		return
	boss_trigger_entered = false
	target_zoom = Vector2(0.5, 0.5) #remove magic number
	setup_camera_limits()
