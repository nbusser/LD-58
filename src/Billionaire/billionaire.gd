class_name Billionaire

extends Node2D

const _JUMP_VELOCITY = -600
const _GRAVITY: float = 1200.0

# Interval range between two attacks, in seconds
@export var idle_range_seconds: Vector2 = Vector2(0.5, 1.0)

var health = 100

var _is_gravity_enabled: bool = true

var _bullet_scene = preload("res://src/Bullet/Bullet.tscn")

@onready var _idle_timer: Timer = $IdleTimer
@onready var _body: CharacterBody2D = $BillionaireBody
@onready var _bullets: Node2D = $Bullets
@onready var _player: Player = $"../Player"
@onready var _shoot_sound: AudioBankPlayer = $SFX/ShootSound
@onready var _rain_focus_sound: AudioBankPlayer = $SFX/RainFocusSound

@onready var _attack_patterns: Node = $AttackPatterns


func _ready() -> void:
	$AttackPatterns/AirShotgun.routine = _air_shotgun_routine
	$AttackPatterns/Rain.routine = _rain_routine


# Return a random attack pattern
func _get_attack_pattern():
	var available_attacks = _attack_patterns.get_children().filter(
		func(attack_pattern: AttackPattern):
			return (
				attack_pattern.enabled
				and attack_pattern.is_ready()
				and health <= attack_pattern.health_threshold
			)
	)
	if available_attacks.size() == 0:
		print("NO ATTACK AVAILABLE !")
		return null
	return available_attacks[randi() % len(available_attacks)]


func _physics_process(delta: float) -> void:
	if _is_gravity_enabled:
		_body.velocity.y += _GRAVITY * delta

	_body.move_and_slide()


func _spawn_bullet(
	bullet_position: Vector2, bullet_direction: Vector2, bullet_speed: float = 100.0
) -> void:
	var bullet: Bullet = _bullet_scene.instantiate()
	bullet.init(bullet_position, bullet_direction, bullet_speed)
	_bullets.add_child(bullet)


func _air_shotgun_routine() -> void:
	# Maybe run
	if Globals.coin_flip():
		var run_direction: float = -1.0 if Globals.coin_flip() else 1.0
		var run_speed: float = 200.0
		var run_accel_duration: float = 0.2
		var run_constant_speed_duration: float = randf_range(0.3, 0.6)
		var run_decel_duration: float = 0.6
		var should_stop_before_jump: bool = Globals.coin_flip() as bool

		# Acceleration
		await (
			get_tree()
			. create_tween()
			. tween_property(_body, "velocity:x", run_direction * run_speed, run_accel_duration)
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
				. tween_property(_body, "velocity:x", 0.0, run_decel_duration)
				. set_trans(Tween.TRANS_LINEAR)
				. set_ease(Tween.EASE_IN_OUT)
				. finished
			)

		if should_stop_before_jump:
			# Wait to be totally stopped to jump
			await run_constant_then_decelerate.call()
		else:
			# Starts jumping while running
			run_constant_then_decelerate.call()

	# Jump
	_body.velocity.y = _JUMP_VELOCITY
	while _body.velocity.y < 0:
		await get_tree().process_frame

	# Freeze in the air
	_is_gravity_enabled = false
	await get_tree().create_timer(0.3).timeout

	# Shoot bullets to the player
	var bullet_direction = (_player.position - _body.position).normalized()
	var angles = [-15, 0, 15]
	for angle in angles:
		var dir = bullet_direction.rotated(deg_to_rad(angle))
		_spawn_bullet(_body.position, dir, 400.0)
	_shoot_sound.play_sound()

	# Freeze
	await get_tree().create_timer(0.3).timeout

	# Fall
	_is_gravity_enabled = true


func _rain_routine() -> void:
	var spawn_rain_coroutine = func() -> void:
		var rain_nb_waves: int = 10
		var rain_nb_bullets_per_waves: int = 3
		var rain_bullet_speed: float = 200.0
		var rain_bullet_interval_duration: float = 0.3
		var rain_bullet_interval_x: int = 10

		for wave in range(rain_nb_waves):
			for bullet in range(rain_nb_bullets_per_waves):
				var bullet_slot = (randi() % 60) - 30
				var bullet_position_x = bullet_slot * rain_bullet_interval_x

				var bullet_position = Vector2(bullet_position_x, -300)
				_spawn_bullet(bullet_position, Vector2.DOWN, rain_bullet_speed)
			await get_tree().create_timer(rain_bullet_interval_duration).timeout

	_rain_focus_sound.play_sound()
	var focus_duration: float = 2.0
	await get_tree().create_timer(focus_duration).timeout

	await spawn_rain_coroutine.call()


func _on_idle_timer_timeout() -> void:
	var attack = _get_attack_pattern()
	if attack != null:
		print("Attack name: ", (attack as AttackPattern).attack_name)
		await (attack as AttackPattern).call_routine()

	_idle_timer.start(randf_range(idle_range_seconds.x, idle_range_seconds.y))
