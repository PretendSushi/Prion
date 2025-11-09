extends Interactable

@onready var text_label = $RichTextLabel

var interaction_text = "smell the flowers"

func _process(delta: float) -> void:
	pass

func _display_text():
	var final_text = prompt_text + interaction_text
	text_label.text = final_text
	
func _remove_text():
	text_label.text = ""
	
func _on_interact(player):
	player.restore_max_hp()
	
