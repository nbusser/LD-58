# WARNING
# This class is jsut a rough port of logic form Player's physics process.
# TODO: refactor this for a more clean code by removing timestamps logic for example.

class_name DashDownManager

extends Node2D

signal dashed_down

enum State { ON_GROUND, READY, DASHING, FINISHED }

const _DASH_SLOWMO_NAME := "player_down_dash"

var _dash_down_state: State = State.ON_GROUND
var _dash_glide_window_start: float = INF

var _dash_velocity_y: Helpers.OneTimeFloat = Helpers.OneTimeFloat.new(0.0)

var _cancel_token: bool = false

@onready var _player: Player = $".."

@onready var _player_stats: PlayerStats:
	get():
		return _player.ps


func _cancel_dash():
	_cancel_token = true


func _dash_slow_mo():
	if Globals.create_slowmo(_DASH_SLOWMO_NAME, _player_stats.dash_slow_factor):
		await get_tree().create_timer(_player_stats.dash_slow_time).timeout
		Globals.cancel_slowmo_if_exists(_DASH_SLOWMO_NAME)


func _dash_down_routine():
	_cancel_token = false

	emit_signal("dashed_down")
	if _player_stats.unlocked_dash_bullet_time:
		_dash_slow_mo.call_deferred()

	_dash_down_state = State.DASHING
	# Impulse value, only pollable once.
	_dash_velocity_y = Helpers.OneTimeFloat.new(_player_stats.down_dash_speed)

	# Cancelable dash.
	var dash_timer = get_tree().create_timer(_player_stats.down_dash_duration)
	while not _cancel_token and dash_timer.time_left > 0.0:
		await get_tree().process_frame

	$Cooldown.start(_player_stats.dash_cooldown)

	_dash_down_state = State.FINISHED
	# Impulse value, only pollable once.
	_dash_velocity_y = Helpers.OneTimeFloat.new(
		-min(_player_stats.down_dash_speed / 2., _player.velocity.y)
	)


func get_dash_velocity() -> Vector2:
	var dash_velocity: Vector2 = Vector2(0.0, _dash_velocity_y.consume())

	# TODO: fix gliding logic
	# if _dash_down_state == State.DASHING and _player_stats.unlocked_dash_glide and now - _dash_glide_window_start < _player_stats.dash_glide_window and (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")):
	# 	if _dash_glide_window_start == INF:
	# 		_dash_glide_window_start = now

	# 	if Input.is_action_just_pressed("move_left"):
	# 		dash_velocity.x -= _player_stats.glide_force
	# 	elif Input.is_action_just_pressed("move_right"):
	# 		dash_velocity.x += _player_stats.glide_force

	return dash_velocity


func _process(_delta: float) -> void:
	if _player.is_on_floor():
		_cancel_dash()
		_dash_down_state = State.ON_GROUND
	elif _dash_down_state == State.ON_GROUND:
		_dash_down_state = State.READY


func try_dash_down() -> bool:
	if (
		Input.is_action_just_pressed("dash_down")
		and _player_stats.unlocked_dash_down
		and _dash_down_state == State.READY
		and $Cooldown.time_left == 0.0
	):
		_dash_down_routine.call_deferred()
		return true
	return false
