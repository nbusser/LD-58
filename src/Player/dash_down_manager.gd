# WARNING
# This class is jsut a rough port of logic form Player's physics process.
# TODO: refactor this for a more clean code by removing timestamps logic for example.

class_name DashDownManager

extends Node2D

signal dashed_down

enum State { ON_GROUND, READY, DASHING_IMPULSE, DASHING, FINISHED }

const _DASH_SLOWMO_NAME := "player_down_dash"

var _previous_dash_timestamp: float = 0.0
var _dash_down_state: State = State.ON_GROUND
var _dash_glide_window_start: float = INF

@onready var _player: Player = $".."

@onready var _player_stats: PlayerStats:
	get():
		return _player.ps


func update(velocity_y: float) -> Vector2:
	var dash_velocity: Vector2 = Vector2.ZERO

	if _player.is_on_floor():
		_dash_down_state = State.ON_GROUND
		return Vector2.ZERO

	var now = Time.get_unix_time_from_system()

	if _dash_down_state == State.DASHING_IMPULSE:
		_dash_down_state = State.DASHING
		dash_velocity.y += _player_stats.down_dash_speed

	if (
		_dash_down_state == State.DASHING
		and now - _previous_dash_timestamp > _player_stats.down_dash_duration
	):
		_dash_down_state = State.FINISHED
		if velocity_y > 0.0:
			dash_velocity.y = -min(_player_stats.down_dash_speed / 2., velocity_y)

	# TODO: fix gliding logic
	# if _dash_down_state == State.DASHING and _player_stats.unlocked_dash_glide and now - _dash_glide_window_start < _player_stats.dash_glide_window and (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")):
	# 	if _dash_glide_window_start == INF:
	# 		_dash_glide_window_start = now

	# 	if Input.is_action_just_pressed("move_left"):
	# 		dash_velocity.x -= _player_stats.glide_force
	# 	elif Input.is_action_just_pressed("move_right"):
	# 		dash_velocity.x += _player_stats.glide_force

	return dash_velocity


func _dash_slow_mo():
	if Globals.create_slowmo(_DASH_SLOWMO_NAME, _player_stats.dash_slow_factor):
		await get_tree().create_timer(_player_stats.dash_slow_time).timeout
		Globals.cancel_slowmo_if_exists(_DASH_SLOWMO_NAME)


func _process(_delta: float) -> void:
	if not _player.is_on_floor() and _dash_down_state == State.ON_GROUND:
		_dash_down_state = State.READY
		# TODO: fix gliding logic
		_dash_glide_window_start = INF


func try_dash_down() -> void:
	var now = Time.get_unix_time_from_system()
	if (
		Input.is_action_just_pressed("dash_down")
		and _player_stats.unlocked_dash_down
		and _dash_down_state == State.READY
		and now - _previous_dash_timestamp > _player_stats.dash_cooldown
	):
		_previous_dash_timestamp = now
		_dash_down_state = State.DASHING_IMPULSE
		emit_signal("dashed_down")
		if _player_stats.unlocked_dash_bullet_time:
			_dash_slow_mo()
