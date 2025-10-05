class_name AttackManager

extends Node

enum MeleeState { NOT_ATTACKING, WINDUP, ACTIVE, RECOVER }

enum Attack { GROUND = 0, AIR = 1 }


class AttackAnimation:
	var windup: String
	var active: String
	var recover: String

	func _init(windup_animation: String, active_animation: String, recover_animation: String):
		windup = windup_animation
		active = active_animation
		recover = recover_animation


var _billionaire_was_punched_in_current_attack = false
var _combo_counter = 0

var _melee_state = MeleeState.NOT_ATTACKING
var _billionaire_in_melee_reach = false

var _attacks_dict: Dictionary[Attack, AttackAnimation] = {
	Attack.GROUND: AttackAnimation.new("attack_windup", "attack_active", "attack_recover"),
	Attack.AIR: AttackAnimation.new("air_attack_windup", "air_attack_active", "air_attack_recover"),
}

var _current_attack: AttackAnimation = null

@onready var _player = $".."
@onready var _sprite = $"../Sprite"


func can_cancel_current_attack() -> bool:
	return _billionaire_was_punched_in_current_attack and _combo_counter < 3


func can_attack() -> bool:
	return _melee_state == MeleeState.NOT_ATTACKING or can_cancel_current_attack()


func _process(_delta: float) -> void:
	if _melee_state == MeleeState.WINDUP:
		_sprite.play(_current_attack.windup)
	elif _melee_state == MeleeState.ACTIVE:
		_sprite.play(_current_attack.active)
	elif _melee_state == MeleeState.RECOVER:
		_sprite.play(_current_attack.recover)


func _attack_finished_cleanup():
	_melee_state = MeleeState.NOT_ATTACKING
	_billionaire_was_punched_in_current_attack = false
	_combo_counter = 0
	_sprite.play("default")


func _attack():
	# Do NOT change attack style during combo
	if _combo_counter == 0:
		_current_attack = _attacks_dict[Attack.GROUND if _player.is_on_floor() else Attack.AIR]

	_billionaire_was_punched_in_current_attack = false
	_combo_counter += 1
	_melee_state = MeleeState.WINDUP
	$AttackSound.play_sound()


func try_attack() -> bool:
	if can_attack():
		_attack()
		return true
	return false


func _punch_billionaire():
	_player.emit_signal("billionaire_punched", _player.melee_damage)
	_billionaire_was_punched_in_current_attack = true
	$PunchSound.play_sound()


func _try_punch_billionaire() -> bool:
	if _melee_state == MeleeState.ACTIVE and _billionaire_in_melee_reach:
		_punch_billionaire()
		return true
	return false


func is_attacking():
	return _melee_state != MeleeState.NOT_ATTACKING


func _on_sprite_animation_changed() -> void:
	if (
		_sprite.animation != _current_attack.windup
		and _sprite.animation != _current_attack.active
		and _sprite.animation != _current_attack.recover
	):
		_melee_state = MeleeState.NOT_ATTACKING


func _on_sprite_animation_finished() -> void:
	if _sprite.animation == _current_attack.windup:
		_melee_state = MeleeState.ACTIVE
	elif _sprite.animation == _current_attack.active:
		_melee_state = MeleeState.RECOVER
	elif _sprite.animation == _current_attack.recover:
		_attack_finished_cleanup()
	_try_punch_billionaire()


func _on_punch_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BILLIONAIRE]):
		_billionaire_in_melee_reach = true
		_try_punch_billionaire()


func _on_punch_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BILLIONAIRE]):
		_billionaire_in_melee_reach = false
