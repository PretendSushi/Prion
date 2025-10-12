extends Node2D

var enemy = null
var SPAWN_INTERVAL = 5.0
var time_passed = 0.0

@onready var player = $Player

func _ready():
	enemy = preload("res://Scenes/enemy.tscn")
	
func _physics_process(delta):
	time_passed += delta
	if time_passed >= SPAWN_INTERVAL:
		time_passed = 0.0
		#CHECK FOR AND SPAWN ENEMIES HERE
		var is_enemies = check_for_enemies()
		if !is_enemies:
			spawn_enemy()
	
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
	enemy_instance.drop_health.connect(_on_enemy_drop_health)
	add_child(enemy_instance)

func _on_enemy_drop_health(health_pickup, x, y) -> void:
	var health_pickup_instance = health_pickup.instantiate()
	health_pickup_instance.global_position = Vector2(x, y)
	health_pickup_instance.picked_up.connect(player._on_health_pickup_picked_up)
	add_child(health_pickup_instance)
