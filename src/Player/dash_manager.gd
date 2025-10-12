class_name DashManager

extends Node2D

enum State {
	NOT_DASHING,
	DASHING,
}

const _DASH_SLOWMO_NAME := "player_dash"

const _DIRECTION_INPUTS: Array[String] = ["move_left", "move_right"]
const _DIRECTION_MODIFIERS: Array[float] = [-1.0, 1.0]

var _dash_state := State.NOT_DASHING

var _dash_velocity_x := Helpers.OneTimeFloat.new(0.0)

var _cancel_token := false

# Timers to bufferize the double direction tap.
# If a direction is tapped while its timer is not to 0, it means we should dash.
@onready var _directions_buffer_timers: Array[SceneTreeTimer] = [
	get_tree().create_timer(0.0), get_tree().create_timer(0.0)
]

@onready var _player: Player = $".."

@onready var _player_stats: PlayerStats:
	get():
		return _player.ps


func is_dashing() -> bool:
	return _dash_state == State.DASHING


# Returns a number between 0 and 100 showing the cooldown of the dash.
func get_dash_percentage_ready() -> float:
	if not _player_stats.unlocked_dash:
		return 0.0
	if $Cooldown.time_left == 0.0:
		return 100.0
	return 100. * $Cooldown.time_left / _player_stats.dash_cooldown


# Called every frame by the player.
func get_dash_velocity() -> Vector2:
	return Vector2(_dash_velocity_x.consume(), 0.0)


func try_dash() -> bool:
	if _dash_state == State.DASHING or not _player_stats.unlocked_dash or $Cooldown.time_left > 0.0:
		return false

	for i_direction in range(2):
		if Input.is_action_just_pressed(_DIRECTION_INPUTS[i_direction]):
			var timer := _directions_buffer_timers[i_direction]
			# Time between the two inputs is too long. Restarting the timer.
			if timer.time_left == 0.0:
				_directions_buffer_timers[i_direction] = get_tree().create_timer(
					_player_stats.dash_window
				)
			else:
				# Player tapped direction fast enough. Trigger dash.
				_dash_routine.call_deferred(_DIRECTION_MODIFIERS[i_direction])
				return true
	return false


func _cancel_dash():
	_cancel_token = true


func _dash_slow_mo():
	if Globals.create_slowmo(_DASH_SLOWMO_NAME, _player_stats.dash_slow_factor):
		await get_tree().create_timer(_player_stats.dash_slow_time).timeout
		Globals.cancel_slowmo_if_exists(_DASH_SLOWMO_NAME)


func _dash_routine(direction_modifier: float) -> void:
	_cancel_token = false
	_dash_state = State.DASHING

	# emit_signal("dashed", 100. * clamp((now - _previous_dash_timestamp) / _player_stats.dash_cooldown, 0., 100.))

	if _player_stats.unlocked_dash_bullet_time:
		_dash_slow_mo.call_deferred()

	# One-time horizontal impulse.
	_dash_velocity_x = Helpers.OneTimeFloat.new(direction_modifier * _player_stats.dash_speed)

	var dash_timer := get_tree().create_timer(_player_stats.dash_duration)
	while dash_timer.time_left > 0.0 and not _cancel_token:
		await get_tree().process_frame

	# Fin du dash
	$Cooldown.start()
	_dash_state = State.NOT_DASHING


func _on_player_player_is_hurt() -> void:
	_cancel_dash()


# Cleanup slowmo.
func _exit_tree() -> void:
	Globals.cancel_slowmo_if_exists(_DASH_SLOWMO_NAME)
