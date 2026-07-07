extends Area2D

class_name Interactable

signal interacted
signal focused
signal unfocused

@export var prompt_text = "[font_size=32]Press "

var is_player_nearby = false
var player_ref = null
const FILEPATH = "res://Resources/InputIconMap.json"

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	for key in InputMap.action_get_events("Interact"):
		if key is InputEventKey:
			prompt_text += "[%s] to " % OS.get_keycode_string(key.physical_keycode)
		else:
			var icon_map = open_icon_map()
			var button := key as InputEventJoypadButton
			for i in icon_map[0]["buttons"]:
				if i["input"] == str(button.button_index):
					prompt_text += "[img=44x44]%s[/img] " % i["icon"] 
					break
	
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
	
func open_icon_map():
	if not FileAccess.file_exists(FILEPATH):
		print("File does not exist: ", FILEPATH)
		return null
	var file = FileAccess.open(FILEPATH, FileAccess.READ)
	if file == null:
		print("Failed to oppen file. Error code: ", FileAccess.get_open_error())
		return null
	var json_text = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_text)
	if data == null:
		print("Failed to parse JSON string. Check if the format is correct.")
		return null
		
	return data
