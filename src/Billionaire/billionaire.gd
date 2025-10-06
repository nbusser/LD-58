class_name Billionaire

extends CharacterBody2D

const _JUMP_VELOCITY = -650
const _GRAVITY: float = 900.0

# Interval range between two attacks, in seconds
@export var idle_range_seconds: Vector2 = Vector2(0.5, 1.0)
@export var coins_per_damage: float = 0.1

var _is_gravity_enabled: bool = true
var _run_velocity: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO

var _bullet_scene = preload("res://src/Bullet/Bullet.tscn")
var _coin_scene = preload("res://src/Coin/Coin.tscn")

var _is_player_dead = false
var _is_level_timeout = false

@onready var _idle_timer: Timer = $IdleTimer
@onready var _bullets: Node2D = $"../Bullets"
@onready var _player: Player = $"../Player"
@onready var _repulse_wave: Node2D = $AttackPatterns/RepulsiveWave/Columns

@onready var _attack_patterns: Node = $AttackPatterns
@onready var _level: Level = $"../.."
@onready var _coins: Node2D = $"../Coins"
@onready var _lasers: Node2D = %Lasers


func _ready() -> void:
	$AttackPatterns/JumpConeBullets.routine = _jump_cone_bullets_routine
	$AttackPatterns/Machinegun.routine = _machinegun_routine
	$AttackPatterns/Rain.routine = _rain_routine
	$AttackPatterns/RepulsiveWave.routine = _repulse_wave_routine
	$AttackPatterns/LaserWarning.routine = _laser_warning_routine
	$AttackPatterns/LaserSweep.routine = _laser_sweep_routine
	$AttackPatterns/LaserCage.routine = _laser_cage_routine

	_init_repulse_wave()


# Return a random attack pattern
func _get_attack_pattern():
	var available_attacks = _attack_patterns.get_children().filter(
		func(attack_pattern: AttackPattern):
			return (
				attack_pattern.enabled
				and attack_pattern.is_ready()
				and (
					_level.level_state.get_percentage_net_worth_remaining()
					<= attack_pattern.net_worth_percent_threshold
				)
			)
	)
	if available_attacks.size() == 0:
		print("NO ATTACK AVAILABLE !")
		return null
	return available_attacks[randi() % len(available_attacks)]


func _physics_process(delta: float) -> void:
	if _is_gravity_enabled:
		velocity.y += _GRAVITY * delta

	var knockback_decay = Vector2(700.0, 1000.0)
	_knockback_velocity.x = move_toward(_knockback_velocity.x, 0.0, knockback_decay.x * delta)
	_knockback_velocity.y = move_toward(_knockback_velocity.y, 0.0, knockback_decay.y * delta)

	velocity.x = _run_velocity.x + _knockback_velocity.x
	velocity.y += _knockback_velocity.y

	move_and_slide()


func _spawn_bullet(
	bullet_position: Vector2,
	bullet_direction: Vector2,
	bullet_knockback: float,
	bullet_speed: float,
	bullet_scale_factor: float,
	bullet_acceleration: float
) -> void:
	var bullet: Bullet = _bullet_scene.instantiate()
	bullet.init(
		bullet_position,
		bullet_direction,
		bullet_knockback,
		bullet_speed,
		bullet_scale_factor,
		bullet_acceleration
	)
	_bullets.add_child(bullet)


func _run(
	run_direction: float = 1.0,
	run_speed: float = 200.0,
	run_accel_duration: float = 0.2,
	run_constant_speed_duration: float = 0.5,
	run_decel_duration = 0.6,
	wait_until_stopped: bool = false
) -> void:
	# Acceleration
	await (
		get_tree()
		. create_tween()
		. tween_property(self, "_run_velocity:x", run_direction * run_speed, run_accel_duration)
		. set_trans(Tween.TRANS_LINEAR)
		. set_ease(Tween.EASE_IN_OUT)
		. finished
	)

	# Constant and speed deceleration in a single coroutine
	var run_constant_then_decelerate = func():
		# Constant speed
		await get_tree().create_timer(run_constant_speed_duration).timeout
		# Deceleration
		await (
			get_tree()
			. create_tween()
			. tween_property(self, "_run_velocity:x", 0.0, run_decel_duration)
			. set_trans(Tween.TRANS_LINEAR)
			. set_ease(Tween.EASE_IN_OUT)
			. finished
		)

	if wait_until_stopped:
		# Wait to be totally stopped to jump
		await run_constant_then_decelerate.call()
	else:
		# Starts jumping while running
		run_constant_then_decelerate.call()


func _random_run():
	var run_direction: float = -1.0 if Globals.coin_flip() else 1.0
	var run_speed: float = 200.0
	var run_accel_duration: float = 0.2
	var run_constant_speed_duration: float = randf_range(0.3, 0.6)
	var run_decel_duration: float = 0.6
	var wait_until_stopped: bool = Globals.coin_flip() as bool
	await _run(
		run_direction,
		run_speed,
		run_accel_duration,
		run_constant_speed_duration,
		run_decel_duration,
		wait_until_stopped
	)


func _jump_cone_bullets_routine() -> void:
	# Maybe run
	if Globals.coin_flip():
		await _random_run()

	# Jump
	$Sprite2D.play("jump")
	velocity.y = _JUMP_VELOCITY
	while velocity.y < 0:
		await get_tree().process_frame

	# Freeze in the air
	_is_gravity_enabled = false
	await get_tree().create_timer(0.3).timeout

	# Shoot bullets to the player
	var bullet_direction = (_player.global_position - global_position).normalized()
	var angles = [-15, 0, 15]
	for angle in angles:
		var dir = bullet_direction.rotated(deg_to_rad(angle))
		_spawn_bullet(global_position, dir, 800, 500.0, 1.0, 1)
	$AttackPatterns/JumpConeBullets/ShootSound.play_sound()

	# Freeze
	await get_tree().create_timer(0.3).timeout

	# Fall
	_is_gravity_enabled = true
	await get_tree().create_timer(0.5).timeout


func _machinegun_routine() -> void:
	# Maybe run
	if Globals.coin_flip():
		await _random_run()

	$AttackPatterns/Machinegun/FocusSound.play_sound()
	await get_tree().create_timer(1.2).timeout
	$Sprite2D.play("machinegun")
	$AttackPatterns/Machinegun/ShootSound.play_sound()
	var nb_bullets = 10
	for _i in range(nb_bullets):
		var bullet_direction = (_player.global_position - global_position).normalized()
		_spawn_bullet(position, bullet_direction, 50, 600.0, 1.0, 0.0)
		await get_tree().create_timer(0.1).timeout


func _rain_routine() -> void:
	var spawn_rain_coroutine = func() -> void:
		var rain_nb_waves: int = 10
		var rain_nb_bullets_per_waves: int = 4
		var rain_bullet_speed: float = 200.0
		var rain_bullet_interval_duration: float = 0.6
		var rain_bullet_interval_x: int = 70
		var rain_bullet_random_interval_y: int = 15

		var spawn_y = $"../BillionaireBorders/Ceiling".position.y + 10
		var min_x = $"../Borders/WallL".position.x + 10
		var max_x = $"../Borders/WallR".position.x - 10
		var nb_slots: int = abs(min_x - max_x) / rain_bullet_interval_x

		# Pattern carpet bombing
		# for i in range(1):
		# 	print(min_x, max_x)
		# 	var bullet_position_x = min_x + (i * rain_bullet_interval_x)
		# 	var bullet_position = Vector2(bullet_position_x, -300)
		# 	_spawn_bullet(bullet_position, Vector2.DOWN, 50, rain_bullet_speed)

		for wave in range(rain_nb_waves):
			var shuffled_slots = range(nb_slots)
			shuffled_slots.shuffle()
			var slot_index = 0
			for bullet in range(rain_nb_bullets_per_waves):
				var bullet_slot = shuffled_slots[slot_index]
				slot_index += 1
				var bullet_position_x = min_x + (bullet_slot * rain_bullet_interval_x)
				var bullet_position_y = spawn_y + randi() % rain_bullet_random_interval_y

				var bullet_position = Vector2(bullet_position_x, bullet_position_y)
				_spawn_bullet(bullet_position, Vector2.DOWN, 50, rain_bullet_speed, 1.0, 800)
			await get_tree().create_timer(rain_bullet_interval_duration).timeout

	$AttackPatterns/Rain/FocusSound.play_sound()

	$Sprite2D.play("focus")
	var focus_duration: float = 2.0
	await get_tree().create_timer(focus_duration).timeout

	$Sprite2D.play("laugh")
	await spawn_rain_coroutine.call()
	$Sprite2D.play("default")


func _init_repulse_wave():
	var on_hit = func(body: Node2D) -> void:
		if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.PLAYER]):
			_player.get_hurt(Vector2(0, 0))

	for column: Area2D in _repulse_wave.get_children():
		column.visible = false
		column.monitoring = false
		column.monitorable = false
		column.connect("body_entered", on_hit)

	_repulse_wave.visible = true


func _repulse_wave_routine():
	var focus_duration: float = 2.0
	$AttackPatterns/RepulsiveWave/FocusSound.play_sound()

	$Sprite2D.play("focus")
	await get_tree().create_timer(focus_duration).timeout
	$Sprite2D.play("laugh")

	for column: Area2D in _repulse_wave.get_children():
		column.visible = true
		column.monitoring = true
		$AttackPatterns/RepulsiveWave/ColumnSound.play_sound()
		await get_tree().create_timer(0.8).timeout

	await get_tree().create_timer(1.0).timeout

	$Sprite2D.play("default")

	for column: Area2D in _repulse_wave.get_children():
		column.visible = false
		column.monitoring = false


func _on_idle_timer_timeout() -> void:
	if _is_player_dead:
		$Sprite2D.play("laugh")
		return
	if _is_level_timeout:
		print("caca")
		$Sprite2D.play("hurt")
		return

	var attack = _get_attack_pattern()
	if attack != null:
		print("Attack name: ", (attack as AttackPattern).attack_name)
		await (attack as AttackPattern).call_routine()

	_idle_timer.start(randf_range(idle_range_seconds.x, idle_range_seconds.y))


func on_level_billionaire_hit(amount: int, _remaining_net_worth: int) -> void:
	$SFX/HurtSound.play_sound()

	if amount >= 0:
		var coins_to_spawn = max(1, int(round(amount * coins_per_damage)))
		for _i in range(coins_to_spawn):
			var coin: Coin = _coin_scene.instantiate()
			var spawn_offset := Vector2(randf_range(-12.0, 12.0), randf_range(-8.0, 0.0))
			coin.init(
				global_position + spawn_offset,
				(
					[
						Collectible.CollectibleType.DOLLAR_COIN,
						Collectible.CollectibleType.DOLLAR_COIN,
						Collectible.CollectibleType.DOLLAR_COIN,
						Collectible.CollectibleType.DOLLAR_BILL,
						Collectible.CollectibleType.DOLLAR_BILL,
						Collectible.CollectibleType.BUNDLE_OF_CASH
					]
					. pick_random()
				)
			)
			var angle := randf_range(-PI / 3, PI / 3)
			var impulse_direction := Vector2.UP.rotated(angle)
			var impulse_speed := randf_range(160.0, 260.0)
			coin.set_deferred("linear_velocity", impulse_direction * impulse_speed)
			coin.set_deferred("angular_velocity", randf_range(-6.0, 6.0))
			_coins.call_deferred("add_child", coin)

	# Red glow on hit
	var glow_routine = func():
		modulate = Color(1, 0, 0)
		await get_tree().create_timer(1.0).timeout
		modulate = Color(1, 1, 1, 1)
	glow_routine.call()

	var knockback_routine = func():
		var min_distance = 100.0
		var max_distance = 200.0

		var distance = global_position.distance_to(_player.global_position)
		distance = clamp(distance, min_distance, max_distance)
		var t = (distance - min_distance) / (max_distance - min_distance)

		var min_force_x = 100.0
		var max_force_x = 650.0
		var knockback_force_x = lerp(max_force_x, min_force_x, t)

		var min_force_y = 45.0
		var max_force_y = 75.0
		var knockback_force_y = lerp(max_force_y, min_force_y, t)

		var knockback_direction = (global_position - _player.global_position).normalized()
		_knockback_velocity.x = knockback_direction.x * knockback_force_x
		_knockback_velocity.y = knockback_direction.y * knockback_force_y

	knockback_routine.call()


func _laser_warning_routine() -> void:
	# Maybe run to reposition
	if Globals.coin_flip():
		await _random_run()

	# Focus animation
	$AttackPatterns/LaserWarning/FocusSound.play_sound()
	$Sprite2D.play("focus")
	await get_tree().create_timer(1.0).timeout

	# Fire lasers at player position
	$Sprite2D.play("laugh")
	await _lasers.laser_warning_pattern(3, 0.4)

	# Wait for lasers to finish
	await get_tree().create_timer(2.0).timeout
	$Sprite2D.play("default")


func _laser_sweep_routine() -> void:
	# Determine sweep direction based on player position
	var sweep_direction = 1 if _player.global_position.x < global_position.x else -1

	# Focus animation
	$AttackPatterns/LaserSweep/FocusSound.play_sound()
	$Sprite2D.play("focus")
	await get_tree().create_timer(1.2).timeout

	# Fire sweeping laser
	$Sprite2D.play("laugh")
	_lasers.laser_sweep_pattern(sweep_direction, 0.4)

	# Wait for laser to finish
	await get_tree().create_timer(4.0).timeout
	$Sprite2D.play("default")


func _laser_cage_routine() -> void:
	# Run towards center
	var center_direction = sign(0.0 - global_position.x)
	if abs(global_position.x) > 100:
		await _run(center_direction, 200.0, 0.2, 0.3, 0.4, true)

	# Focus animation
	$AttackPatterns/LaserCage/FocusSound.play_sound()
	$Sprite2D.play("focus")
	await get_tree().create_timer(1.5).timeout

	# Create laser cage
	$Sprite2D.play("laugh")
	await _lasers.laser_cage_pattern()

	# Wait for cage to finish
	await get_tree().create_timer(4.0).timeout
	$Sprite2D.play("default")


func _on_sprite_2d_animation_finished() -> void:
	$Sprite2D.play("default")


# Waits for next idle, then waits for Level to continue
func on_player_dies():
	_is_player_dead = true


func on_level_timeout():
	_is_level_timeout = true
