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
	var decoded = get_note_decoded(content)
	var last_scan_percent = get_note_last_scan_percent(content)
	var decoded_words = get_decoded_words(content)
	var note = decode_note(encoded,decoded,25,last_scan_percent,decoded_words)
	note_content.append_text(note)

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
	
func get_note_decoded(note_content):
	var json = JSON.new()
	var result = json.parse(note_content)
	if result == OK:
		var data = json.get_data()
		return data["content"]
	return null

func get_note_last_scan_percent(note_content):
	var json = JSON.new()
	var result = json.parse(note_content)
	if result == OK:
		var data = json.get_data()
		return data["last_precent_decode"]
	return null
	
func get_decoded_words(note_content):
	var json = JSON.new()
	var result = json.parse(note_content)
	if result == OK:
		var data = json.get_data()
		return data["decoded_words"]
	return null
	
func decode_note(note_encoded, note_decoded, scan_percent, last_percent_decode, dec_word_idxs):
	#This method needs testing
	if scan_percent == 100:
		return note_decoded
	scan_percent = scan_percent - last_percent_decode
	var enc_words = note_encoded.split(" ") #array of words ENCODED (random ASCII)
	var dec_words = note_decoded.split(" ") #array of words DECODED (real English words)
	var dec_word_count = int(dec_words.size() * scan_percent / 100) #The number of words that need to be decoded
	
	#loop for the number of words that need to be decoded
	for i in dec_word_count: 
		var idx = randi_range(0, enc_words.size() - 1) #generate a random number
		while idx in dec_word_idxs: #if that word is already decoded, keep generating numbers until we get one that isn't
			idx = randi_range(0, enc_words.size() - 1) 
		enc_words[idx] = dec_words[idx] #replace the encoded word with the decoded word
		dec_word_idxs.append(idx) #add the index to the list of indeces of decoded words
	
	note_encoded = " ".join(enc_words) #replace the original encoded note with the partially decoded one
	return note_encoded
