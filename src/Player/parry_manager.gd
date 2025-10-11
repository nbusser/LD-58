extends Node2D

enum State { NOT_PARRYING, PARRY_ACTIVE, PARRY_RECOVER }

const _PARRY_GLOW_DURATION: float = 0.5
const _PARRY_STATE_DURATION_FRAMES: Dictionary[State, int] = {
	State.PARRY_ACTIVE: 30, State.PARRY_RECOVER: 30
}

var _parry_state: State = State.NOT_PARRYING

# When set to true, cancels the current parry stance
var _cancel_token: bool = false

@onready var _sprite: AnimatedSprite2D = $"../Sprite"


func _cancel_parry() -> void:
	_cancel_token = true


func is_in_parrying_stance() -> bool:
	return _parry_state != State.NOT_PARRYING


func _is_parry_active() -> bool:
	return _parry_state == State.PARRY_ACTIVE


func _finish_parrying() -> void:
	_cancel_token = false
	_parry_state = State.NOT_PARRYING


func _play_parry_state(parry_state: State) -> bool:
	assert(parry_state != State.NOT_PARRYING, "Use _finish_parrying() instead")

	_parry_state = parry_state
	var frame_counter = 0
	while frame_counter < _PARRY_STATE_DURATION_FRAMES[parry_state] and not _cancel_token:
		frame_counter += 1
		await get_tree().process_frame
	return _cancel_token


func _parying_stance() -> void:
	_cancel_token = false
	if await _play_parry_state(State.PARRY_ACTIVE):
		return _finish_parrying()

	await _play_parry_state(State.PARRY_RECOVER)
	_finish_parrying()


func try_parrying_stance() -> bool:
	if is_in_parrying_stance():
		return false
	_parying_stance()
	return true


func _parry_gfx() -> void:
	_sprite.modulate = Color("#37fcfc", 0.7)
	await get_tree().create_timer(_PARRY_GLOW_DURATION).timeout
	_sprite.modulate = Color(1, 1, 1, 1)


func _parry() -> void:
	print("Parried !")
	_parry_gfx.call_deferred()
	# TODO: freeze frame
	$ParrySound.play()
	_cancel_parry()


func try_parry() -> bool:
	if _is_parry_active():
		_parry()
		return true
	return false


func _process(_detla: float) -> void:
	if is_in_parrying_stance():
		_sprite.play("parry_active")


func _on_player_player_is_hurt() -> void:
	_cancel_parry()
