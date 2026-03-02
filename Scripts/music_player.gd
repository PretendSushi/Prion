extends AudioStreamPlayer

@onready var music = $"."

var current_track : AudioStream

func _ready():
	music.play()

func play_music(track_path):
	var track = load(track_path)
	
	if current_track == track:
		return
	
	current_track = track
	stream = track
	play()

func get_track_for_level(level):
	print(level)
	var file := FileAccess.open("res://Resources/LevelMusic.json", FileAccess.READ)
	if file == null:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var result = json.parse(content)
	if result == OK:
		for i in json.data:
			if str(level) == i["levelName"]:
				return i["musicPath"]
	return null
