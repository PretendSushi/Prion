extends Control

@onready var control_box = $ControlBox

var waiting_for_input = false
var action_to_rebind = null
var current_label = null
var current_button = null
var config = ConfigFile.new()

const DEFAULT_MSG = "Press any key to change binding..."
const UNAVAIL_MSG = "Key is already being used by another action"

func _ready():
	for action: String in InputMap.get_actions():
		if not action.contains("ui"):
			var hbox = HBoxContainer.new()
			var label = Label.new()
			var inst_label = Label.new()
			var button = Button.new()
			
			label.text = action
			inst_label.text = DEFAULT_MSG
			inst_label.visible = false
			
			var events = InputMap.action_get_events(action)
			for event in events:
				if event is InputEventKey:
					button.text = event.as_text()
					break
				button.text = "Undefined"
			button.pressed.connect(_on_button_pressed.bind(action, button, inst_label))
			button.focus_mode = Control.FOCUS_NONE
			
			hbox.add_child(label)
			hbox.add_child(button)
			hbox.add_child(inst_label)
			
			control_box.add_child(hbox)

func _process(float) -> void:
	pass

func _on_button_pressed(action, button, label):
	label.visible = true
	current_label = label
	current_button = button
	
	waiting_for_input = true
	action_to_rebind = action
	
func _input(event):
	if waiting_for_input and event is InputEventKey and event.pressed:
		if not event.pressed:
			return  # Only handle presses
		if event.is_echo():
			return  # Ignore repeated events
		
		if check_if_key_available(event):
			rebind_action(action_to_rebind, event.keycode)
			update_button(current_button, event.as_text())
			waiting_for_input = false
			current_label.visible = false
			save_input_settings()
			reset_label_message()
		else:
			show_key_unavailable_msg()
	
func rebind_action(action, new_key):
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	
	var new_event := InputEventKey.new()
	new_event.keycode = new_key
	new_event.pressed = true
	InputMap.action_add_event(action, new_event)
	
func update_button(button, keycode):
	button.text = str(keycode)
	
func check_if_key_available(key):
	for action in InputMap.get_actions():
		if action == action_to_rebind:
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				if event.keycode == key.keycode:
					return false
	return true

func show_key_unavailable_msg():
	current_label.text = UNAVAIL_MSG

func reset_label_message():
	current_label.text = DEFAULT_MSG

func save_input_settings():
	for action in InputMap.get_actions():
		var events = InputMap.action_get_events(action)
		config.set_value("input", action, events)
		
	config.save("user://input.cfg")
