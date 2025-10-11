class_name JumpManager

extends Node2D

var _is_keep_pressing_jump_button: bool = false

# Set to true while player is ascending
var _is_actively_jumping: bool = false

var _jump_load_start: float = INF
var _play_jump_start_ts: float = INF

@onready var _player: Player = $".."
@onready var _sprite: AnimatedSprite2D = $"../Sprite"

@onready var _player_stats: PlayerStats:
	get():
		return _player.ps

@onready var _current_nb_jumps_left: int = _player_stats.max_nb_jumps


func get_jump_load_timestamp() -> float:
	return _jump_load_start


func is_jumping_or_falling() -> bool:
	return not _player.is_on_floor()


func reset_jumps() -> void:
	_current_nb_jumps_left = _player_stats.max_nb_jumps


func try_jump() -> bool:
	# Jump
	if (
		not Input.is_action_pressed("jump")
		or _is_keep_pressing_jump_button  # No automatic jump when space is kept pressed
		or _current_nb_jumps_left == 0
	):  # If no jump left
		return false

	# Cleans up gravity
	_player.velocity.y = 0

	_current_nb_jumps_left -= 1

	_is_actively_jumping = true
	_jump_load_start = Time.get_unix_time_from_system()

	return true


# Update current jump's characteristics and returns the current frame's jump velocity.
func update(delta: float) -> float:
	var now = Time.get_unix_time_from_system()

	var vertical_velocity: float = 0.0

	var time_since_jump = now - _jump_load_start
	if (
		_is_actively_jumping
		and Input.is_action_pressed("jump")
		and time_since_jump < _player_stats.max_input_jump_time
	):
		var timer_proportion = (
			(
				1
				- (
					clamp(time_since_jump, 0, _player_stats.max_input_jump_time)
					/ _player_stats.max_input_jump_time
				)
			)
			** 4
		)
		vertical_velocity = -_player_stats.jump_force * delta * timer_proportion
		# Show animation for double jump
		if not _player.is_on_floor():
			_play_jump_start_ts = now
	elif (
		_is_actively_jumping
		and (
			time_since_jump > _player_stats.max_input_jump_time
			or Input.is_action_just_released("jump")
		)
	):
		_is_actively_jumping = false

	return vertical_velocity


func _physics_process(_delta):
	if _player.is_on_floor():
		reset_jumps()

	if Input.is_action_pressed("jump"):
		_is_keep_pressing_jump_button = true
	elif Input.is_action_just_released("jump"):
		_is_keep_pressing_jump_button = false


# Grant bonus jump after attack if the conditions are met.
func try_grant_bonus_jump(connected_attack: AttackManager.Attack) -> bool:
	if (
		connected_attack == AttackManager.Attack.AIR
		and _player_stats.unlocked_bonus_jump_after_airhit
		and _current_nb_jumps_left == 0
	):
		_current_nb_jumps_left += 1
		return true
	return false


# Plays the right jumping animation if the player is in the air.
func try_play_jumping_or_falling_animation(velocity_y: float):
	if not is_jumping_or_falling():
		return false

	if velocity_y >= 140 or Time.get_unix_time_from_system() - _play_jump_start_ts < .05:
		_sprite.play("jump_end")
	elif velocity_y <= 0:
		_sprite.play("jump_start")
	else:
		_sprite.play("jump_middle")
	return true


func _on_player_wall_sticked(now: float) -> void:
	_jump_load_start = now


func _on_player_dashed_down() -> void:
	_jump_load_start = INF
	_is_actively_jumping = false
