extends CanvasLayer

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	var view_size = get_viewport().get_visible_rect().size
	var frame_texture = animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation,
		animated_sprite.frame
	)
	var anim_size = frame_texture.get_size()
	var anim_scale = view_size/anim_size
	animated_sprite.scale = anim_scale
	animated_sprite.position = view_size / 2
	animated_sprite.play("loading")
