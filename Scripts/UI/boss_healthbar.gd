extends Node2D

const BAR_TWEEN_DURATION = 0.2

@onready var bar = $ProgressBar

func _ready() -> void:
	pass
	

func _on_hand_boss_initialize_health_bar(max_health) -> void:
	_ready()
	bar.max_value = max_health
	bar.value = max_health


func _on_hand_boss_update_health_bar(health) -> void:
	var healthbar_tween = get_tree().create_tween()
	healthbar_tween.tween_property(bar, "value", health, BAR_TWEEN_DURATION)
