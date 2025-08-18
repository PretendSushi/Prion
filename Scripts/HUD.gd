extends Control

@onready var healthbar = $Healthbar

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_player_initialize_health(max_health, health):
	_ready()
	healthbar.max_value = max_health
	healthbar.value = health


func _on_player_health_changed(health):
	var healthbar_tween = get_tree().create_tween()
	healthbar_tween.tween_property(healthbar, "value", health, 0.2)
