extends Node

func _ready():
	load_input_settings()
	
func load_input_settings():
	var config = ConfigFile.new()
	if config.load("user://input.cfg") == OK:
		for action in config.get_section_keys("input"):
			InputMap.action_erase_events(action)
			
			var events = config.get_value("input", action)
			for event in events:
				InputMap.action_add_event(action, event)
