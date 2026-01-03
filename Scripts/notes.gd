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
	if notes_list.size() > 0:
		default_note = notes_list[notes_list.size() - 1]
		for note in notes_list:
			create_button(note)
		var content_path = "res://Assets/Notes/" + default_note + ".json"
		var meta_path = "user://Notes/" + default_note + ".json"
		var note = set_up_note(content_path, meta_path)
		note_content.append_text(note)

func create_button(label):
	var button = Button.new()
	button.text = label
	button.name = label.replace(" ", "_")
	button.pressed.connect(Callable(self, "_on_note_changed").bind([button]))
	button_container.add_child(button)
	
func load_note_content(path):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	
	var content = file.get_as_text()
	file.close()
	
	return content

func parse_note(note):
	if note != null:
		var json = JSON.new()
		var result = json.parse(note)
		if result == OK:
			var data = json.get_data()
			print(data)
			return data
	return null

func get_note_encoded(note_content):
	if note_content != null and note_content.has("encoded"):
		return note_content["encoded"]
	return null
	
func get_note_decoded(note_content):
	if note_content != null and note_content.has("content"):
		return note_content["content"]
	return null

func get_note_last_scan_percent(note_content):
	if note_content != null and note_content.has("last_percent_decode"):
		return note_content["last_percent_decode"]
	return 0
	
func get_decoded_words(note_content):
	if note_content != null and note_content.has("decoded_words"):
		return note_content["decoded_words"]
	return []
	
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
		return get_part_decoded_note(file_path)
	
	#loop for the number of words that need to be decoded
	for i in dec_word_count: 
		var idx = randi_range(0, enc_words.size() - 1) #generate a random number
		while idx in dec_word_idxs: #if that word is already decoded, keep generating numbers until we get one that isn't
			idx = randi_range(0, enc_words.size() - 1) 
		enc_words[idx] = dec_words[idx] #replace the encoded word with the decoded word
		dec_word_idxs.append(idx) #add the index to the list of indeces of decoded words
	
	var new_note = " ".join(enc_words) #replace the original encoded note with the partially decoded one
	update_note_meta(file_path, dec_word_idxs, scan_percent, new_note) #the note metadata needs to be saved
	return new_note
	
func _on_note_changed(button):
	button = button[0]
	note_content.text = ""
	var content_path = "res://Assets/Notes/" + button.text + ".json"
	var meta_path = "user://Notes/" + button.text + ".json"
	var note = set_up_note(content_path, meta_path)
	note_content.append_text(note)

func set_up_note(content_path, meta_path):
	var content = load_note_content(content_path)
	var meta_content = load_note_content(meta_path)
	
	var parsed_note = parse_note(content)
	var parsed_meta = parse_note(meta_content)
	var encoded = get_note_encoded(parsed_note)
	var decoded = get_note_decoded(parsed_note)
	var last_scan_percent = get_note_last_scan_percent(parsed_meta)
	var decoded_words = get_decoded_words(parsed_meta)
	
	return decode_note(encoded, decoded, 75, last_scan_percent, decoded_words, meta_path)
	
func update_note_meta(file_path, dec_words, scan_perc, new_note):
	var data = {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file != null:
		var json_string = file.get_as_text()
		file.close()
		
		var result = JSON.parse_string(json_string)
		if result == null:
			print("Failed to parse JSON.")
			return
		
		data = result
		
	data["decoded_words"] = dec_words
	data["last_percent_decode"] = scan_perc
	data["new_note"] = new_note
		
	var file_write := FileAccess.open(file_path, FileAccess.WRITE)
	if file_write == null:
		DirAccess.make_dir_absolute("user://Notes")
		file_write = FileAccess.open(file_path, FileAccess.WRITE)
	if file_write:
		var updated_json = JSON.stringify(data, "\t")
		file_write.store_string(updated_json)
		file_write.close()
		print("JSON file updated successfully")
	else:
		print("Failed to open file for writing")

#This method should only be called by decode_note. This method ONLY decodes the words in the note that have already been decoded
func get_part_decoded_note(file_path):
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var content_str = file.get_as_text()
		var content = JSON.parse_string(content_str)
		if content.has("new_note"):
			return content["new_note"]
		else:
			return null
	else:
		return null

func _on_player_note_added(note) -> void:
	create_button(note)
