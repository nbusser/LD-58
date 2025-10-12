class_name DashDownManager

extends Node2D

signal dashed_down

enum State { ON_GROUND, READY, DASHING, FINISHED }

const _DASH_SLOWMO_NAME := "player_down_dash"

var _dash_down_state: State = State.ON_GROUND

var _dash_velocity_x: Helpers.OneTimeFloat = Helpers.OneTimeFloat.new(0.0)
var _dash_velocity_y: Helpers.OneTimeFloat = Helpers.OneTimeFloat.new(0.0)

var _cancel_token: bool = false

@onready var _player: Player = $".."

@onready var _player_stats: PlayerStats:
	get():
		return _player.ps


func is_dashing() -> bool:
	return _dash_down_state == State.DASHING


# If we touch ground or got hurt for example.
func _cancel_dash():
	_cancel_token = true


func _dash_slow_mo():
	if Globals.create_slowmo(_DASH_SLOWMO_NAME, _player_stats.dash_slow_factor):
		await get_tree().create_timer(_player_stats.dash_slow_time).timeout
		Globals.cancel_slowmo_if_exists(_DASH_SLOWMO_NAME)


func _dash_down_routine():
	_dash_down_state = State.DASHING
	_cancel_token = false

	emit_signal("dashed_down")
	if _player_stats.unlocked_dash_bullet_time:
		_dash_slow_mo.call_deferred()

	# Impulse value, only pollable once.
	_dash_velocity_y = Helpers.OneTimeFloat.new(_player_stats.down_dash_speed)

	# Cancelable dash.
	var dash_timer: SceneTreeTimer = get_tree().create_timer(_player_stats.down_dash_duration)

	var glide_window_timer: SceneTreeTimer = get_tree().create_timer(
		_player_stats.dash_glide_window
	)
	var has_gliden: bool = false

	while not _cancel_token and dash_timer.time_left > 0.0:
		await get_tree().process_frame

		# Handle glide: if player tap direction a short time after starting the dash, it can give an horizontal impulse.
		if (
			not has_gliden
			and _player_stats.unlocked_dash_glide
			and glide_window_timer.time_left > 0.0
		):
			if Input.is_action_just_pressed("move_left"):
				# We give one time x impulse.
				_dash_velocity_x = Helpers.OneTimeFloat.new(-_player_stats.glide_force)
				has_gliden = true
			elif Input.is_action_just_pressed("move_right"):
				_dash_velocity_x = Helpers.OneTimeFloat.new(_player_stats.glide_force)
				has_gliden = true

	$Cooldown.start(_player_stats.dash_cooldown)

	_dash_down_state = State.FINISHED
	# Impulse value, only pollable once.
	_dash_velocity_y = Helpers.OneTimeFloat.new(
		-min(_player_stats.down_dash_speed / 2., _player.velocity.y)
	)


# Called every frame by the player.
# The impulse is properly set asynchronously by _dash_down_routine coroutine.
func get_dash_velocity() -> Vector2:
	return Vector2(_dash_velocity_x.consume(), _dash_velocity_y.consume())


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


func _on_player_player_is_hurt() -> void:
	_cancel_dash()


# Cleanup slowmo.
func _exit_tree() -> void:
	Globals.cancel_slowmo_if_exists(_DASH_SLOWMO_NAME)
