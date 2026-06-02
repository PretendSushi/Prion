extends Node2D

#Signals
signal player_leech

#Constants
const RUBBER_BAND_PROTEIN_COST = 40
const LEECH_HEALTH_GAIN = 25
const STICKY_BAND_SPEED = 1800

#Available abilities
enum StandardAbilities { LIQUIFY, RUBBER_BAND, STICKY_BAND, HELICOPTER, ZERO_GRAV }

#Modules
var state_machine
var timers
var movement
var collisions
var attacks
var player

#Variables
var unlocked_standard_abilities

func init():
	state_machine = $"../StateMachine"
	timers = $"../Timers"
	movement = $"../Movement"
	collisions = $"../Collisions"
	attacks = $"../Attacks"
	player = $".."
	unlocked_standard_abilities = []
	
	add_standard_abilities(
		[StandardAbilities.HELICOPTER,
		StandardAbilities.RUBBER_BAND,
		StandardAbilities.STICKY_BAND,
		StandardAbilities.ZERO_GRAV]
	)

func rubber_band():
	if state_machine.get_action_state() == state_machine.ActionState.RUBBER_BAND\
	or player.protein < RUBBER_BAND_PROTEIN_COST\
	or !is_standard_ability_unlocked(StandardAbilities.RUBBER_BAND):
		return
	state_machine.set_action_state(state_machine.ActionState.RUBBER_BAND)
	state_machine.set_rubber_band_state(state_machine.RubberBandState.START)
	
func sticky_band(hitbox, body):
	if !is_standard_ability_unlocked(StandardAbilities.STICKY_BAND) and !player.god_mode:
		return
	state_machine.set_rubber_band_state(state_machine.RubberBandState.STICKY_BAND)
	player.velocity.y = 0
	player.velocity.x = STICKY_BAND_SPEED * movement.get_direction()

func zero_grav():
	if state_machine.get_action_state() == state_machine.ActionState.ZERO_GRAV\
	or timers.get_zero_grav_cooldown_flag()\
	or !is_standard_ability_unlocked(StandardAbilities.ZERO_GRAV):
		return
	state_machine.set_action_state(state_machine.ActionState.ZERO_GRAV)
	timers.set_zero_grav_timer()
	
func leech():
	if state_machine.get_action_state() == state_machine.ActionState.LEECH:
		return
	state_machine.set_action_state(state_machine.ActionState.LEECH)
	state_machine.set_leech_state(state_machine.LeechState.START)
	
func is_leech_successful():
	var hitbox = collisions.get_leech_right()
	if movement.direction_lit == movement.Directions.LEFT:
		hitbox = collisions.get_leech_left()
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Enemy"):
			player_leech.connect(body._on_player_leech.bind())
			emit_signal("player_leech", attacks.ATTACK_DAMAGE)
			on_leech_successful()
			return true
	return false
	
func on_leech_successful():
	if player.health + LEECH_HEALTH_GAIN >= 100:
		player.health = 100
	else:
		player.health += LEECH_HEALTH_GAIN
	print("hit")
	player.update_health()

func is_standard_ability_unlocked(target_ability: StandardAbilities):
	if player.god_mode:
		return true
	for ability in unlocked_standard_abilities:
		if ability == target_ability:
			return true
	return false
	
func get_unlocked_standard_abilities():
	return unlocked_standard_abilities
	
func add_standard_abilities(abilities: Array[StandardAbilities]):
	if abilities.size() == 0:
		return
	for ability in abilities:
		unlocked_standard_abilities.append(ability)

func remove_standard_ability(ability: StandardAbilities):
	if unlocked_standard_abilities.has(ability):
		unlocked_standard_abilities.erase(ability)
		return true
	return false
