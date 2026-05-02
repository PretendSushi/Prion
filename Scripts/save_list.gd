extends Control

signal back_button_pressed

@onready var vbox = $VBoxContainer
@onready var back_btn = $BackBtn

func _ready() -> void:
	var saves = SaveManager.get_all_saves()
	
	for save in saves:
		if !SaveManager.is_valid_save_file(save):
			continue
		var button = Button.new()
		button.text = save
		vbox.add_child(button)
		button.pressed.connect(_on_button_pressed.bind(save))

func _on_button_pressed(save):
	SaveManager.load_game(save)


func _on_back_btn_pressed() -> void:
	emit_signal("back_button_pressed")
