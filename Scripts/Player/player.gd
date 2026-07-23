extends CharacterBody2D

#signals
signal health_changed
signal protein_changed
signal initialize_health
signal initialize_protein
signal show_inventory
signal initialize_inventory
signal interacted
signal note_added
signal update_camera
signal update_camera_follow_speed

#Constants
const MAX_HEALTH = 100
const MAX_PROTEIN = 100
const STEP_PITCH_LOW = 0.80
const STEP_PITCH_HIGH = 1.20
#Paths for sound effects
const STEP_SFX_PATH = "res://Assets/Sounds/Player/Step.wav"

#variables for sound effects
var step_sfx

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 1800#ProjectSettings.get_setting("physics/2d/default_gravity")
#You know what this tracks
var health = 100
#Basically mana
var protein = 100
#This is a list of all notes the player has collected
var notes_list = []
#The current interactable object available to the player
var current_interactable = null

#debug tool
var god_mode = false

#Sound effects
enum SoundEffects { WALK }

#Any children of the player that are needed in the code are here
@onready var animated_sprite = $AnimatedSprite2D

@onready var hit_anim = $HitFlashAnim
@onready var audio_player = $AudioPlayer

#Modules
@onready var state_machine = $StateMachine
@onready var player_timers = $Timers
@onready var movement = $Movement
@onready var animations = $Animations
@onready var collisions = $Collisions
@onready var attacks = $Attacks
@onready var abilities = $Abilities
@onready var save_manager = $SaveManager

func _ready():
	state_machine.init()
	player_timers.init()
	movement.init()
	animations.init()
	collisions.init()
	attacks.init()
	abilities.init()
	save_manager.init()
	if RoomManager.player_stats != null:
		apply_data(RoomManager.player_stats)
		animations.flip_for_direction()
	if health <= 0:
		restore_max_hp()
		hit_anim.stop()
		hit_anim.seek(0, true)
		animated_sprite.material.set_shader_parameter("hit_flash_on", 0.0)
	#initialize everything
	emit_signal("initialize_health", MAX_HEALTH, health)
	emit_signal("initialize_protein", MAX_PROTEIN, protein)
	emit_signal("initialize_inventory", notes_list)
	
	step_sfx = load(STEP_SFX_PATH)
	audio_player.stream = step_sfx
	audio_player.max_distance = 5000

func _physics_process(delta):
	if !player_timers.handle_knockback(delta):
		movement.move(delta)
	player_timers.handle_knockback(delta)
	player_timers.handle_invincibility(delta)
	player_timers.handle_zero_grav(delta)
	animations.play_animations()
	check_for_inputs(delta)
	movement.handle_jump_helper(delta)
	movement.handle_falling(delta)
	player_timers.handle_jump_off(delta)
	movement.check_wall_cling()
	player_timers.handle_fall_timer(delta)
	move_and_slide()
	
func _input(event):
	if event is InputEventJoypadButton and event.pressed:
		print("Button index:", event.button_index)

func check_for_inputs(delta):
	#Movement inputs are not checked here
	#Check for attack input 
	if Input.is_action_just_pressed("Attack"):
		#This needs to be made more readable. Takes attack takes two arguments, whether up or down are being pressed
		attacks.attack()
	#Check for open inventory input, and emit the signal so the inventory code can handle the rest
	if Input.is_action_just_pressed("Inventory"):
		emit_signal("show_inventory")
	if Input.is_action_just_pressed("RubberBand"):
		abilities.rubber_band()
	if Input.is_action_just_pressed("Interact"):
		interact()
	if Input.is_action_just_pressed("ZeroGrav"):
		abilities.zero_grav()
	if Input.is_action_just_pressed("Leech"):
		abilities.leech()
	if Input.is_action_just_pressed("Jump"):
		movement.handle_jump(delta)
	if Input.is_action_pressed("Sprint"):
		movement.handle_sprint()
	if Input.is_action_just_released("Sprint"):
		movement.handle_stop_sprint()
	if Input.is_action_just_pressed("Dash"):
		movement.dash_start()

func _on_enemy_hit_player(damage, knockback, enemy_pos):
	if player_timers.get_invincible_flag() or god_mode:
		return
	hit_anim.play("hit")
	health -= damage
	emit_signal("health_changed", health)
	#handle knockback
	take_knockback(enemy_pos, knockback)
	#handle invincibility
	player_timers.set_invincible_flag(true)
	player_timers.set_invincible_timer()
	#handle cancelling rubberband
	if state_machine.get_action_state() == state_machine.ActionState.RUBBER_BAND and state_machine.get_rubber_band_state() != state_machine.RubberBandState.IDLE:
		state_machine.set_action_state(state_machine.ActionState.IDLE)
		state_machine.set_rubber_band_state(state_machine.RubberBandState.IDLE)
	#handle death
	if health <= 0:
		die()

func take_knockback(enemy_pos, knockback):
	var kb_dir = 0
	if enemy_pos.x < global_position.x:
		kb_dir = 1
	else: 
		kb_dir = -1
	velocity.x = knockback * kb_dir
	velocity.y = -player_timers.V_KNOCKBACK
	player_timers.set_knockback_timer()

func die():
	if god_mode:
		return
	if !RoomManager.last_save_point:
		print("Error, no save point found")
		return
	if RoomManager.last_save_point.room_id != RoomManager.get_room_data().room_id:
		#RoomManager.get_room_path_by_id(RoomManager.last_save_point.room_id)
		RoomManager.change_level(RoomManager.last_save_point)
	else:
		global_position.x = RoomManager.last_save_point.player_x
		global_position.y = RoomManager.last_save_point.player_y
	CustomStatTracker.add_death()

func _on_interactable_focused(interactable) -> void:
	current_interactable = interactable

func _on_interactable_unfocused(interactable) -> void:
	if current_interactable == interactable:
		current_interactable = null
		
func _on_pickupable_picked_up(pickupable, value) -> void:
	if pickupable.name == "HealthPickup":
		handle_health_pickup(value)
	if pickupable.name == "ProteinPickup":
		handle_protein_pickup(value)

func handle_health_pickup(health_gain):
	if health + health_gain >= MAX_HEALTH:
		health = MAX_HEALTH
	elif health < MAX_HEALTH:
		health += health_gain
	emit_signal("health_changed", health)
	
func handle_protein_pickup(protein_gain):
	if protein + protein_gain >= MAX_PROTEIN:
		protein = MAX_PROTEIN
	elif protein < MAX_PROTEIN:
		protein += protein_gain
	emit_signal("protein_changed", protein)
	
func handle_protein_changed():
	emit_signal("protein_changed", protein)
	
func interact():
	if current_interactable == null:
		return
	interacted.connect(current_interactable._on_interact.bind())
	emit_signal("interacted", self)

func restore_max_hp():
	health = MAX_HEALTH
	emit_signal("health_changed", health)
	
func add_note(note_name):
	notes_list.append(note_name)
	emit_signal("note_added", note_name)
	
func get_data_as_dict():
	return {
		"health": health,
		"protein": protein,
		"direction": movement.get_direction(),
		"direction_lit": movement.get_direction_lit()
	}
	
func apply_data(data):
	health = data.health
	protein = data.protein
	movement.set_direction(data.direction)
	movement.set_direction_lit(data.direction_lit)

func play_sounds(sound_effect: SoundEffects):
	if sound_effect == SoundEffects.WALK:
		if !audio_player.playing:
			audio_player.pitch_scale = randf_range(STEP_PITCH_LOW, STEP_PITCH_HIGH) 
			audio_player.play()

func activate_god_mode():
	god_mode = true
	
func deactivate_god_mode():
	god_mode = false

func update_health():
	emit_signal("health_changed", health)
	
func update_protein():
	emit_signal("protein_changed", protein)

func change_camera_follow_speed(speed):
	emit_signal("update_camera_follow_speed", speed)
