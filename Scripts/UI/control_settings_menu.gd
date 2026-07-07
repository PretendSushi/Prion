extends Control

@onready var control_box = $ControlBox
@onready var vbox_kbd = $ControlBox/VScrollBar/VBoxKBD
@onready var vbox_jpd = $ControlBox/VScrollBar/VBoxJPD

signal back

var waiting_for_input = false
var action_to_rebind = null
var current_label = null
var current_button = null
var buttons = []
var config = ConfigFile.new()

const DEFAULT_MSG = "Press any key to change binding..."
const UNAVAIL_MSG = "Key is already being used by another action"
const JPD_MTN_MSG = "This button cannot be remapped"

const filepath = "res://Resources/InputIconMap.json"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	#create keyboard inputs
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
			
			buttons.append(button)
			
			hbox.add_child(label)
			hbox.add_child(button)
			hbox.add_child(inst_label)
			
			vbox_kbd.add_child(hbox)
			
	#create joypad inputs
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
			var screen_scale = DisplayServer.screen_get_scale()
			var icon_map = open_icon_map()
			for event in events:
				if event is InputEventJoypadButton:
					for i in icon_map[0]["buttons"]:
						if i["input"] == str(event.button_index):
							button.add_theme_constant_override("icon_max_width", 32 * screen_scale)
							button.flat = true
							button.icon = load(i["icon"])
							break
				elif event is InputEventJoypadMotion:
					for i in icon_map[1]["joystick"]:
						if i["axis"] == event.axis and i["axis_value"] == event.axis_value:
							button.add_theme_constant_override("icon_max_width", 32 * screen_scale)
							button.flat = true
							button.icon = load(i["icon"])
							break
			button.pressed.connect(_on_button_pressed.bind(action, button, inst_label))
			button.focus_mode = Control.FOCUS_NONE
			
			buttons.append(button)
			
			hbox.add_child(label)
			hbox.add_child(button)
			hbox.add_child(inst_label)
			
			vbox_jpd.add_child(hbox)
			vbox_jpd.visible = false
	
func _process(float) -> void:
	pass

func open_icon_map():
	if not FileAccess.file_exists(filepath):
		print("File does not exist: ", filepath)
		return null
	var file = FileAccess.open(filepath, FileAccess.READ)
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

func _on_button_pressed(action, button, label):
	label.visible = true
	current_label = label
	current_button = button
	
	waiting_for_input = true
	action_to_rebind = action
	disable_unfocused_buttons()
	
func _input(event):
	if waiting_for_input and (event is InputEventKey or event is InputEventJoypadButton): #and event.pressed:
		if not event.pressed:
			return  # Only handle presses
		if event.is_echo():
			return  # Ignore repeated events
		
		if event is InputEventKey and check_if_key_available(event):
			rebind_action_kbd(action_to_rebind, event.keycode)
			update_button_kbd(current_button, event.as_text())
			waiting_for_input = false
			current_label.visible = false
			save_input_settings()
			reset_label_message()
			reenable_buttons()
		elif event is InputEventJoypadButton:
			rebind_action_jpd(action_to_rebind, event.button_index)
			update_button_jpd(current_button, event)
			waiting_for_input = false
			current_label.visible = false
			save_input_settings()
			reset_label_message()
			reenable_buttons()
		elif event is InputEventJoypadMotion and check_if_btn_available(event):
			show_jpd_mtn_unavailable_msg()
		else:
			show_key_unavailable_msg()
	
func rebind_action_kbd(action, new_key):
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	
	var new_event := InputEventKey.new()
	new_event.keycode = new_key
	new_event.pressed = true
	InputMap.action_add_event(action, new_event)

func rebind_action_jpd(action, new_btn):
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			InputMap.action_erase_event(action, event)
	
	var new_event = InputEventJoypadButton.new()
	new_event.button_index = new_btn
	new_event.pressed = true
		
	InputMap.action_add_event(action, new_event)

func update_button_kbd(button, keycode):
	button.text = str(keycode)
	
func update_button_jpd(button, event):
	var icon_map = open_icon_map()
	for i in icon_map[0]["buttons"]:
		if i["input"] == str(event.button_index):
			button.icon = load(i["icon"])
	
func check_if_key_available(key):
	for action in InputMap.get_actions():
		if action == action_to_rebind:
			continue
		if action.contains("ui"):
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and key is InputEventKey:
				if event.keycode == key.keycode:
					return false
	return true
	
func check_if_btn_available(btn):
	for action in InputMap.get_actions():
		if action == action_to_rebind:
			continue
		if action.contains("ui"):
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton and btn is InputEventJoypadButton:
				if event.button_index == btn.button_index:
					return false
	return true

func show_key_unavailable_msg():
	current_label.text = UNAVAIL_MSG
	
func show_jpd_mtn_unavailable_msg():
	current_label.text = JPD_MTN_MSG

func reset_label_message():
	current_label.text = DEFAULT_MSG

func save_input_settings():
	for action in InputMap.get_actions():
		var events = InputMap.action_get_events(action)
		config.set_value("input", action, events)
		
	config.save("user://input.cfg")
	
func disable_unfocused_buttons():
	for button in buttons:
		if button == current_button:
			continue
		button.disabled = true

func reenable_buttons():
	for button in buttons:
		button.disabled = false
		
func _on_back_btn_pressed() -> void:
	emit_signal("back")

func _on_keyboard_btn_pressed() -> void:
	vbox_kbd.visible = true
	vbox_jpd.visible = false

func _on_controller_btn_pressed() -> void:
	vbox_kbd.visible = false
	vbox_jpd.visible = true
