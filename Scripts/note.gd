extends Interactable

const COLL_NOTE_IDS_PATH = "user://CollectedNoteIDs.json"

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
	record_collected_note()
	queue_free()

func record_collected_note():
	var file = FileAccess.open(COLL_NOTE_IDS_PATH, FileAccess.WRITE)
	if file:
		var note_to_store = str(note_data.note_id)
		var json_note = JSON.stringify(note_to_store, "\t")
		file.store_string(json_note)
