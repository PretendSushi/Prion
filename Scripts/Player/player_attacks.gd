extends Node2D

#Signals
signal player_attack

#Constants
const ATTACK_DAMAGE = 40
const KNOCKBACK = 1000
const RUBBER_BAND_DAMAGE = 80
const RUBBER_BAND_PROTEIN_COST = 40 

#Modules
var state_machine
var movement
var collisions

#Nodes
var player

func init():
	state_machine = $"../StateMachine"
	movement = $"../Movement"
	collisions = $"../Collisions"
	player = $".."

func attack():
	#the player can only attack once, then not again until the end of the animation
	if state_machine.get_action_state() == state_machine.ActionState.ATTACK or state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV:
		return
	#if it is a legit attack, set the state
	state_machine.set_action_state(state_machine.ActionState.ATTACK)
	#Decide which hitbox to use
	var hitbox = collisions.get_attack_hitbox()
	#Find every NPC who should take damage
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.name.contains("Enemy"):
			player_attack.connect(body._on_player_attack.bind())
			emit_signal("player_attack", ATTACK_DAMAGE, KNOCKBACK)
			if hitbox == collisions.get_bottom_hitbox():
				movement.bounce()
		if body.is_in_group("Barrier"):
			player_attack.connect(body._on_player_attack.bind())
			emit_signal("player_attack")

func rubber_band_attack():
	var hitbox = collisions.get_rubber_band_hitbox()
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.name == "Enemy":
			player_attack.connect(body._on_player_attack.bind())
			emit_signal("player_attack", RUBBER_BAND_DAMAGE, KNOCKBACK)
		if body.name == "TileMap":
			player.sticky_band(hitbox, body)
	if !player.god_mode:
		player.protein -= RUBBER_BAND_PROTEIN_COST
		emit_signal("protein_changed", player.protein)
