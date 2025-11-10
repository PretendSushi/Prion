extends Control

@onready var healthbar = $Healthbar
@onready var proteinbar = $Proteinbar

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

func _on_player_initialize_protein(max_protein, protein) -> void:
	_ready()
	proteinbar.max_value = max_protein
	proteinbar.value = protein

func _on_player_health_changed(health):
	var healthbar_tween = get_tree().create_tween()
	healthbar_tween.tween_property(healthbar, "value", health, 0.2)

func _on_player_protein_changed(protein) -> void:
	var protein_tween = get_tree().create_tween()
	protein_tween.tween_property(proteinbar, "value", protein, 0.2)
