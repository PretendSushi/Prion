extends Area2D

class_name Interactable

signal interacted
signal focused
signal unfocused

@export var prompt_text = "Press "

var is_player_nearby = false
var player_ref = null

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	for key in InputMap.action_get_events("Interact"):
		prompt_text += "[%s] to " % OS.get_keycode_string(key.physical_keycode)
	
func _process(delta: float) -> void:
	pass
	
func interact() -> void:
	if !is_player_nearby:
		return
	emit_signal("interacted", player_ref)
	
func _on_interact(target) -> void:
	print("To be overridden")
	
func _display_text() -> void:
	print("To be overridden")
	
func _remove_text() -> void:
	print("To be overridden")

func _on_body_entered(body):
	if body.name == "Player":
		is_player_nearby = true
		player_ref = body
		focused.connect(body._on_interactable_focused.bind())
		emit_signal("focused", self)
		_display_text()
		
func _on_body_exited(body):
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		unfocused.connect(body._on_interactable_unfocused.bind())
		emit_signal("unfocused", self)
		_remove_text()
	
