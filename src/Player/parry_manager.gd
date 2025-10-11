class_name ParryManager

extends Node2D

# High level abstraction of parry state
# - NOT_PARRYING:   player is not at all in parry logic.
# - PARRY_READY:    player is in parry stance. If an attack connects at this specific moment,
#				    it will be sucesfully parried
# - PARRY_ACTIVE:   player is actively blocking an incoming attack.
#                   The game's speed is greatly reduced until this state finishes.
#                   The parry will be totally canceled after it finishes.
# - PARRY_RECOVER:  player is still in parry stance. Any incoming attack will NOT be blocked.
# - PARRY_FINISHED: transition state, getting directly to NOT_PARRYING.
enum State { NOT_PARRYING, PARRY_READY, PARRY_ACTIVE, PARRY_RECOVER, PARRY_FINISHED }

# Token used to cancel a parry mid-way, with a specific reason.
enum CancelToken {
	NOT_CANCELED,
	GOT_HURT,
	GOT_PARRIED,
}

const _PARRY_SLOWMO_NAME = "PARRY_FREEZE_FRAME"

# Duration of each parry state
const _PARRY_STATE_DURATION_FRAMES: Dictionary[State, int] = {
	State.PARRY_READY: 30, State.PARRY_ACTIVE: 30, State.PARRY_RECOVER: 30
}

var _parry_state: State = State.NOT_PARRYING

var _cancel_token: CancelToken = CancelToken.NOT_CANCELED

@onready var _sprite: AnimatedSprite2D = $"../Sprite"

@onready var _player: Player = $".."

@onready var _player_stats: PlayerStats:
	get():
		return _player.ps


# When called, will cancel the current parry and jump directly to NOT_PARRYING.
func _cancel_parry(reason: CancelToken) -> void:
	assert(reason != CancelToken.NOT_CANCELED, "Cannot cancel a parry with NOT_CANCELED")
	_cancel_token = reason


# Embbeds all parry states.
func is_in_parrying_stance() -> bool:
	return _parry_state != State.NOT_PARRYING


func _finish_parrying() -> void:
	_cancel_token = CancelToken.NOT_CANCELED
	_parry_state = State.NOT_PARRYING


func _play_parry_state(parry_state: State) -> CancelToken:
	assert(parry_state != State.NOT_PARRYING, "Use _finish_parrying() instead")

	_parry_state = parry_state
	var frame_counter = 0
	# Cannot cancel an active parry.
	while (
		frame_counter < _PARRY_STATE_DURATION_FRAMES[parry_state]
		and (parry_state == State.PARRY_ACTIVE or _cancel_token == CancelToken.NOT_CANCELED)
	):
		frame_counter += 1
		await get_tree().process_frame
	return _cancel_token


# Plays the full process of parry stance.
func _parying_stance() -> void:
	# Routine ran when an attack was succesfully parried.
	var active_parry_routine = func() -> void:
		$ParrySound.play()
		_sprite.modulate = Color("#37fcfc", 0.7)
		# "Freeze" game for _PARRY_FREEZE_DURATION_FRAMES frames
		if Globals.create_slowmo(_PARRY_SLOWMO_NAME, 0.01):
			await _play_parry_state(State.PARRY_ACTIVE)
			Globals.cancel_slowmo_if_exists(_PARRY_SLOWMO_NAME)
		_sprite.modulate = Color(1, 1, 1, 1)

	# ------

	_cancel_token = CancelToken.NOT_CANCELED

	# Run PARRY_READY state, then evaluate why it finished.
	match await _play_parry_state(State.PARRY_READY):
		# The parry was not canceled -> switch to recovery state.
		CancelToken.NOT_CANCELED:
			await _play_parry_state(State.PARRY_RECOVER)
		# Got hurt by an unparyable attack -> directly finish the parry.
		CancelToken.GOT_HURT:
			pass
		# Parried an attack -> run the appropriate routine
		CancelToken.GOT_PARRIED:
			await active_parry_routine.call()

	_parry_state = State.PARRY_FINISHED


# Called when parry command is pressed.
# Returns whether the player went to parry process or not.
func try_parrying_stance() -> bool:
	if (
		Input.is_action_just_pressed("Parry")
		and _player_stats.unlocked_parry
		and not is_in_parrying_stance()
	):
		_parying_stance()
		return true
	return false


# Called when an attack connects with player.
# Returns whether the attack was parried or not.
func try_parry() -> bool:
	match _parry_state:
		# Parry is already active. Ignoring.
		State.PARRY_ACTIVE:
			return true
		# Activate parry. Will cancel the current animation to switch to parry active routine.
		State.PARRY_READY:
			_cancel_parry(CancelToken.GOT_PARRIED)
			return true
		# No parry.
		_:
			return false


# Sets the appropriate animation depending on the parry state.
func _process(_detla: float) -> void:
	match _parry_state:
		State.PARRY_READY:
			_sprite.play("parry_ready")
		State.PARRY_ACTIVE:
			_sprite.play("parry_active")
		State.PARRY_RECOVER:
			_sprite.play("parry_recover")
		State.PARRY_FINISHED:
			_finish_parrying()
		_:
			pass


# If player is touched during the recover.
# Will cancel the current parry animation.
func _on_player_player_is_hurt() -> void:
	_cancel_parry(CancelToken.GOT_HURT)
