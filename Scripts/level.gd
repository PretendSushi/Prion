extends Node2D

var enemy = null
var adjacent_rooms = []
var SPAWN_INTERVAL = 5.0
var time_passed = 0.0
@onready var player = $Player

func _ready():
	enemy = preload("res://Scenes/enemy.tscn")
	if RoomManager.player_x != null and RoomManager.player_y != null:
		position_player(RoomManager.player_x, RoomManager.player_y)
		position_camera(RoomManager.player_x, RoomManager.player_y)
		RoomManager.nullify_player_coords()
		
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy_instance in enemies:
		enemy_instance.hit_player.connect(player._on_enemy_hit_player)
		enemy_instance.drop_health.connect(_on_enemy_drop_health)
		enemy_instance.drop_protein.connect(_on_enemy_drop_protein)
	
	var room_data = RoomManager.get_room_data()
	if room_data:
		player.auto_move_on_room_change(room_data.entrance_way)
	
func _physics_process(delta):
	pass
	#time_passed += delta
	#if time_passed >= SPAWN_INTERVAL:
		#time_passed = 0.0
		##CHECK FOR AND SPAWN ENEMIES HERE
		#var is_enemies = check_for_enemies()
		#if !is_enemies:
			#spawn_enemy()
			
func position_player(x, y):
	var player = get_tree().get_nodes_in_group("Player")[0]
	player.global_position.x = x
	player.global_position.y = y
	
func position_camera(x, y):
	var camera = get_tree().get_nodes_in_group("Camera")[0]
	camera.global_position.x = x
	camera.global_position.y = y
	

func check_for_enemies():
	var children = get_all_nodes(get_children())
	for child in children:
		if child.name == "Enemy":
			return true
	return false
		
#pass null to this method to start the search, use the node parameter for the recursion
func get_all_nodes(children):
	var nodes = []
	for child in children:
		nodes.append(child)
		nodes += get_all_nodes(child.get_children())
	return nodes
		
func spawn_enemy():
	var enemy_instance = enemy.instantiate()
	enemy_instance.hit_player.connect(player._on_enemy_hit_player)
	enemy_instance.drop_health.connect(_on_enemy_drop_health)
	enemy_instance.drop_protein.connect(_on_enemy_drop_protein)
	add_child(enemy_instance)

func _on_enemy_drop_health(health_pickup, x, y) -> void:
	var health_pickup_instance = health_pickup.instantiate()
	health_pickup_instance.global_position = Vector2(x, y)
	add_child(health_pickup_instance)

func _on_enemy_drop_protein(protein_pickup, x, y) -> void:
	var protein_pickup_instance = protein_pickup.instantiate()
	protein_pickup_instance.global_position = Vector2(x, y)
	add_child(protein_pickup_instance)
