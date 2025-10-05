class_name AttackManager

extends Node

enum MeleeState { NOT_ATTACKING, WINDUP, ACTIVE, RECOVER }
var _billionaire_was_punched_in_current_attack = false
var _combo_counter = 0

var _melee_state = MeleeState.NOT_ATTACKING
var _billionaire_in_melee_reach = false

@onready var _player = $".."
@onready var _sprite = $"../Sprite"


func can_cancel_current_attack() -> bool:
	return _billionaire_was_punched_in_current_attack and _combo_counter < 3


func can_attack() -> bool:
	return _melee_state == MeleeState.NOT_ATTACKING or can_cancel_current_attack()


func _attack_finished_cleanup():
	_melee_state = MeleeState.NOT_ATTACKING
	_billionaire_was_punched_in_current_attack = false
	_combo_counter = 0
	_sprite.play("default")


func _attack():
	_billionaire_was_punched_in_current_attack = false
	_combo_counter += 1
	_melee_state = MeleeState.WINDUP
	$AttackSound.play_sound()
	_sprite.play("attack_windup")


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
		_sprite.animation != "attack_windup"
		and _sprite.animation != "attack_active"
		and _sprite.animation != "attack_recover"
	):
		_melee_state = MeleeState.NOT_ATTACKING


func _on_sprite_animation_finished() -> void:
	if _sprite.animation == "attack_windup":
		_melee_state = MeleeState.ACTIVE
		_sprite.play("attack_active")
	elif _sprite.animation == "attack_active":
		_melee_state = MeleeState.RECOVER
		_sprite.play("attack_recover")
	elif _sprite.animation == "attack_recover":
		_attack_finished_cleanup()
	_try_punch_billionaire()


func _on_punch_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BILLIONAIRE]):
		_billionaire_in_melee_reach = true
		_try_punch_billionaire()


func _on_punch_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BILLIONAIRE]):
		_billionaire_in_melee_reach = false
