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
	var path = "res://Assets/Notes/" + default_note + ".json"
	var encoded = get_note_encoded(content)
	var decoded = get_note_decoded(content)
	var last_scan_percent = get_note_last_scan_percent(content)
	var decoded_words = get_decoded_words(content)
	var note = decode_note(encoded,decoded,75,last_scan_percent,decoded_words, path)
	note_content.append_text(note)

func create_button(label):
	var button = Button.new()
	button.text = label
	button.name = label.replace(" ", "_")
	button.pressed.connect(Callable(self, "_on_note_changed").bind([button]))
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
	
func decode_note(note_encoded, note_decoded, scan_percent, last_percent_decode, dec_word_idxs, file_path):
	#This method needs testing
	if scan_percent == 100:
		return note_decoded
	var curr_scan_percent = scan_percent - last_percent_decode
	var enc_words = note_encoded.split(" ") #array of words ENCODED (random ASCII)
	var dec_words = note_decoded.split(" ") #array of words DECODED (real English words)
	var dec_word_count = int(dec_words.size() * curr_scan_percent / 100) #The number of words that need to be decoded
	
	#if the note has no new words to decode, then we just need to spit out the version that was already decoded
	if dec_word_count == 0:
		return redecode_note(note_encoded, note_decoded, dec_word_idxs)
	
	#loop for the number of words that need to be decoded
	for i in dec_word_count: 
		var idx = randi_range(0, enc_words.size() - 1) #generate a random number
		while idx in dec_word_idxs: #if that word is already decoded, keep generating numbers until we get one that isn't
			idx = randi_range(0, enc_words.size() - 1) 
		enc_words[idx] = dec_words[idx] #replace the encoded word with the decoded word
		dec_word_idxs.append(idx) #add the index to the list of indeces of decoded words
	
	update_note_meta(file_path, dec_word_idxs, scan_percent) #the note metadata needs to be saved
	note_encoded = " ".join(enc_words) #replace the original encoded note with the partially decoded one
	return note_encoded
	
func _on_note_changed(button):
	button = button[0]
	note_content.text = ""
	var content = load_note_content(button.text)
	var path = "res://Assets/Notes/" + button.text + ".json"
	var encoded = get_note_encoded(content)
	var decoded = get_note_decoded(content)
	var last_scan_percent = get_note_last_scan_percent(content)
	var decoded_words = get_decoded_words(content)
	var note = decode_note(encoded,decoded,75,last_scan_percent,decoded_words, path)	
	note_content.append_text(note)
	
func update_note_meta(file_path, dec_words, scan_perc):
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("File not found or failed to open")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var result = JSON.parse_string(json_string)
	if result == null:
		print("Failed to parse JSON.")
		return
	
	var data = result
	
	if data.has("decoded_words"):
		data["decoded_words"] = dec_words
	else:
		print("decoded_words not found in JSON")
		return
		
	if data.has("last_precent_decode"):
		data["last_precent_decode"] = scan_perc
	else:
		print("last_precent_decode not found in JSON")
		return
		
	var file_write := FileAccess.open(file_path, FileAccess.WRITE)
	if file_write:
		var updated_json = JSON.stringify(data, "\t")
		file_write.store_string(updated_json)
		file_write.close()
		print("JSON file updated successfully")
	else:
		print("Failed to open file for writing")
		
#This method should only be called by decode_note. This method ONLY decodes the words in the note that have already been decoded
func redecode_note(encoded_note, decoded_note, dec_word_idxs):
	var enc_words = encoded_note.split(" ") #array of words ENCODED (random ASCII)
	var dec_words = decoded_note.split(" ") #array of words DECODED (real English words)
	var new_note = enc_words
	for i in dec_word_idxs.size():
		new_note[dec_word_idxs[i]] = dec_words[dec_word_idxs[i]]
	new_note = " ".join(new_note) 
	return new_note 
	
