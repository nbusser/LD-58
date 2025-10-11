# WARNINGa
# This class is jsut a rough port of logic form Player's physics process.
# TODO: refactor this for a more clean code by removing timestamps logic for example.

class_name DashManager

extends Node2D

signal dashed(dash_cooldown: float)

const _DASH_SLOWMO_NAME := "player_dash"

var _previous_dash_timestamp: float = 0.0
var _previous_dir_timestamps: Array[float] = [0.0, 0.0]  # left, right

@onready var _player: Player = $".."

@onready var _player_stats: PlayerStats:
	get():
		return _player.ps


func _dash_slow_mo():
	if Globals.create_slowmo(_DASH_SLOWMO_NAME, _player_stats.dash_slow_factor):
		await get_tree().create_timer(_player_stats.dash_slow_time).timeout
		Globals.cancel_slowmo_if_exists(_DASH_SLOWMO_NAME)


func try_dash() -> Vector2:
	var now: float = Time.get_unix_time_from_system()

	var dash_velocity: Vector2 = Vector2.ZERO
	if _player_stats.unlocked_dash:
		for direction in range(2):
			if Input.is_action_just_pressed(_player.DIRECTIONS[direction]):
				if now - _previous_dash_timestamp > _player_stats.dash_cooldown:
					if now - _previous_dir_timestamps[direction] < _player_stats.dash_window:
						_previous_dash_timestamp = now
						dash_velocity.x = (
							_player.DIRECTIONS_MODIFIERS[direction] * _player_stats.dash_speed
						)
						if _player_stats.unlocked_dash_bullet_time:
							_dash_slow_mo()
					_previous_dir_timestamps[direction] = now
		emit_signal(
			"dashed",
			100. * clamp((now - _previous_dash_timestamp) / _player_stats.dash_cooldown, 0., 100.)
		)
		# _hud.set_dash_cooldown(100. * clamp((now - previous_dash) / ps.dash_cooldown, 0., 100.))

	return dash_velocity
