extends Interactable

@onready var text_label = $RichTextLabel

var interaction_text = "pick up note"
var note_name

@export var note_data: NoteData

func _ready():
	super._ready()
	note_name = note_data.note_name

func _display_text():
	var final_text = prompt_text + interaction_text
	text_label.text = final_text

func _remove_text():
	text_label.text = ""
	
func _on_interact(player):
	player.add_note(note_name)
	queue_free()
