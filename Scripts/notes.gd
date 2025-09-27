extends Control

@onready var note_content = $TextureRect/NoteContent
@onready var button_container = $ButtonContainer
var default_note = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_player_show_inventory() -> void:
	
	visible = !visible


func _on_player_initialize_inventory(notes_list) -> void:
	default_note = notes_list[notes_list.size() - 1]
	for note in notes_list:
		create_button(note)
	var content = load_note_content(default_note)
	var encoded = get_note_encoded(content)
	note_content.append_text(encoded)

func create_button(label):
	var button = Button.new()
	button.text = label
	button.name = label.replace(" ", "_")
	button_container.add_child(button)
	
func load_note_content(note_name):
	var path = "res://Assets/Notes/" + note_name + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	
	var content = file.get_as_text()
	file.close()
	
	return content

func get_note_encoded(note_content):
	var json = JSON.new()
	var result = json.parse(note_content)
	if result == OK:
		var data = json.get_data()
		return data["encoded"]
	return null
	
