class_name AttackManager

extends Node

# Logic state machine:
# Not attacking:
#	- any other animation is playing
# Windup:
#	- startup frame of the attack
#	- no active hitbox
#	- cannot be canceled
# Active:
#	- active frames of the attack
#	- billionaire takes damage (once) if he enters hitbox
#	- as soon as billionaire is hit, can be canceled
# Recover:
#	- recover frames
#	- no active hitbox
#	- if billionaire was hit during active phase, can be canceled
# Finished:
#	- no associated animation
#	- waiting for cleanup by _process()
enum AttackState { NOT_ATTACKING, WINDUP, ACTIVE, RECOVER, FINISHED }

# Type of attack we are throwing
# UNSPECIFIED -> empty state
enum Attack { UNSPECIFIED, GROUND, AIR }


# struct collecting the three animation names for each attack phase
class AttackAnimation:
	var windup: String
	var active: String
	var recover: String

	func _init(windup_animation: String, active_animation: String, recover_animation: String):
		windup = windup_animation
		active = active_animation
		recover = recover_animation


# Max consecutive cancels
const MAX_CANCELS = 3

# If billionaire is hit, allows an attack cancel
var _billionaire_was_punched_in_current_attack: bool = false
var _cancel_counter: int = 0

var _billionaire_in_melee_reach: bool = false

var _attack_state: AttackState = AttackState.NOT_ATTACKING
var _current_attack: Attack = Attack.UNSPECIFIED

# Associates an attack type with its animation labels
var _attacks_dict: Dictionary[Attack, AttackAnimation] = {
	Attack.GROUND: AttackAnimation.new("attack_windup", "attack_active", "attack_recover"),
	Attack.AIR: AttackAnimation.new("air_attack_windup", "air_attack_active", "air_attack_recover"),
}

@onready var _player: Player = $".."
@onready var _sprite: AnimatedSprite2D = $"../Sprite"


# Billionaire was hit in current attack and we did not reached max combo
func _can_cancel_current_attack() -> bool:
	return _billionaire_was_punched_in_current_attack and _cancel_counter < MAX_CANCELS


func can_attack() -> bool:
	return _attack_state == AttackState.NOT_ATTACKING or _can_cancel_current_attack()


func is_attacking() -> bool:
	return _attack_state != AttackState.NOT_ATTACKING


func _process(_delta: float) -> void:
	# Cancels air attack if we just landed
	if _current_attack == Attack.AIR and _player.is_on_floor():
		_attack_state = AttackState.FINISHED

	# Plays animation matching the current logical state
	if _attack_state == AttackState.WINDUP:
		_sprite.play(_attacks_dict[_current_attack].windup)
	elif _attack_state == AttackState.ACTIVE:
		_sprite.play(_attacks_dict[_current_attack].active)
	elif _attack_state == AttackState.RECOVER:
		_sprite.play(_attacks_dict[_current_attack].recover)
	elif _attack_state == AttackState.FINISHED:
		_attack_finished_cleanup()


func _attack_finished_cleanup() -> void:
	_attack_state = AttackState.NOT_ATTACKING
	_current_attack = Attack.UNSPECIFIED
	_billionaire_was_punched_in_current_attack = false
	_cancel_counter = 0
	_sprite.play("default")


func _attack() -> void:
	# Do NOT change attack style during combo
	# i.e, GROUND attack, hit, jump, cancel attack mid-air -> will throw another GROUND attack
	if _cancel_counter == 0:
		_current_attack = Attack.GROUND if _player.is_on_floor() else Attack.AIR

	_billionaire_was_punched_in_current_attack = false
	_cancel_counter += 1
	_attack_state = AttackState.WINDUP
	$AttackSound.play_sound()


func try_attack() -> bool:
	if can_attack():
		_attack()
		return true
	return false


func _punch_billionaire() -> void:
	_player.emit_signal("billionaire_punched", _player.melee_damage)
	_billionaire_was_punched_in_current_attack = true
	$PunchSound.play_sound()


func _try_punch_billionaire() -> bool:
	if (
		_attack_state == AttackState.ACTIVE
		and _billionaire_in_melee_reach
		and not _billionaire_was_punched_in_current_attack
	):
		_punch_billionaire()
		return true
	return false


func _on_sprite_animation_changed() -> void:
	if not is_attacking():
		return
	if (
		_sprite.animation != _attacks_dict[_current_attack].windup
		and _sprite.animation != _attacks_dict[_current_attack].active
		and _sprite.animation != _attacks_dict[_current_attack].recover
	):
		_attack_state = AttackState.NOT_ATTACKING


# Go to next attack state
func _on_sprite_animation_finished() -> void:
	if not is_attacking():
		return

	if _sprite.animation == _attacks_dict[_current_attack].windup:
		_attack_state = AttackState.ACTIVE
	elif _sprite.animation == _attacks_dict[_current_attack].active:
		_attack_state = AttackState.RECOVER
	elif _sprite.animation == _attacks_dict[_current_attack].recover:
		_attack_state = AttackState.FINISHED
	_try_punch_billionaire()


func _on_punch_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BILLIONAIRE]):
		_billionaire_in_melee_reach = true
		_try_punch_billionaire()


func _on_punch_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BILLIONAIRE]):
		_billionaire_in_melee_reach = false
