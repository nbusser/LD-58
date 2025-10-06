class_name Player
extends CharacterBody2D

signal billionaire_punched(damage: int)

enum Direction { LEFT = -1, RIGHT = 1 }

const DIRECTIONS = ["move_left", "move_right"]
const DIRECTIONS_MODIFIERS = [-1, 1]
const DASH_SLOWMO_NAME := "player_dash"
const BULLET_PROXIMITY_SLOWMO_NAME := "bullet_proximity"

@export var is_dead_animation_playing = false
@export var enable_gravity = true

var ps: PlayerStats

var is_dead = false
var is_level_timeout = false

var jump_load_start = null
var is_actively_jumping = false
var is_keep_pressing_jump_button = false
var is_down_dashing = false
var can_down_dash = false
var is_in_billionaire = false
var is_on_top_of_billionaire = false
var dash_glide_window_start = 0

var intouchable = false

var direction = Direction.RIGHT

var previous_dir = [0, 0]  # left, right
var previous_dash = 0
var previous_down_dash = 0
var previous_melee = 0
var previous_head_bounce = 0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var current_nb_jumps_left = 2

var prev_velocity = Vector2(0, 0)
var play_jump_start_ts = 0

var health = 10

var bullets_in_proximity: Array[Node2D] = []

@onready var _hurt_sound = $SoundFx/HurtSound
@onready var _punch_area: Area2D = $PunchArea
@onready var _smash_area: Area2D = $SmashArea
@onready var _bullet_time_area: Area2D = $BulletTimeArea
@onready var _hud: HUD = $"../../UI/HUD"
@onready var _level: Node = $"../.."
@onready var _camera: Node = $"../Camera2D"
@onready var _original_scale = scale


func _ready() -> void:
	# Waits for Game.gd to run randomize()
	await get_tree().process_frame
	_hud.update_life(health)

	# Setup bullet time area
	if _bullet_time_area:
		_bullet_time_area.area_entered.connect(_on_bullet_time_area_entered)
		_bullet_time_area.area_exited.connect(_on_bullet_time_area_exited)
		# Update bullet time area radius from player stats
		for c in _bullet_time_area.get_children():
			if c is CollisionShape2D:
				var shape = c.shape
				if shape is CircleShape2D:
					shape.radius = ps.bullet_proximity_radius


func init(ps_p: PlayerStats):
	ps = ps_p


func _physics_process(delta):
	var vt_velocity = 0.
	var hz_velocity = 0.
	var now = Time.get_unix_time_from_system()

	if is_on_floor():
		current_nb_jumps_left = ps.max_nb_jumps

	if _can_move():
		# Horizontal movement
		var input_direction = Input.get_axis("move_left", "move_right")
		if input_direction != 0:
			direction = Direction.LEFT if input_direction == -1 else Direction.RIGHT

		($Sprite as AnimatedSprite2D).flip_h = direction == Direction.LEFT

		hz_velocity = input_direction * (ps.ground_speed if self.is_on_floor() else ps.air_speed)

		# Jump
		if (
			not is_keep_pressing_jump_button  # No automatic jump when space is kept pressed
			and current_nb_jumps_left > 0  # As long as we have remaining jumps
			and Input.is_action_pressed("jump")
		):
			# Cleans up gravity
			velocity.y = 0
			current_nb_jumps_left -= 1
			is_actively_jumping = true
			jump_load_start = now
		var time_since_jump = now - (jump_load_start if jump_load_start != null else INF)
		if (
			is_actively_jumping
			&& Input.is_action_pressed("jump")
			&& time_since_jump < ps.max_input_jump_time
		):
			is_keep_pressing_jump_button = true
			var timer_proportion = (
				(1 - clamp(time_since_jump, 0, ps.max_input_jump_time) / ps.max_input_jump_time)
				** 4
			)
			vt_velocity = -ps.jump_force * delta * timer_proportion
			# Show animation for double jump
			if !is_on_floor():
				play_jump_start_ts = now
		elif (
			is_actively_jumping
			&& (time_since_jump > ps.max_input_jump_time || Input.is_action_just_released("jump"))
		):
			is_actively_jumping = false

		if Input.is_action_just_released("jump"):
			is_keep_pressing_jump_button = false

		# Horizontal dash
		if ps.unlocked_dash:
			for dir in range(2):
				if Input.is_action_just_pressed(DIRECTIONS[dir]):
					if now - previous_dash > ps.dash_cooldown:
						if now - previous_dir[dir] < ps.dash_window:
							previous_dash = now
							hz_velocity = DIRECTIONS_MODIFIERS[dir] * ps.dash_speed
							if ps.unlocked_dash_bullet_time:
								dash_slow_mo()
						previous_dir[dir] = now
			_hud.set_dash_cooldown(100. * clamp((now - previous_dash) / ps.dash_cooldown, 0., 100.))

		# Down dash
		if ps.unlocked_dash_down:
			if is_on_floor():
				can_down_dash = true
				is_down_dashing = false

			if (
				Input.is_action_just_pressed("dash_down")
				&& can_down_dash
				&& !is_on_floor()
				&& !is_down_dashing
				&& now - previous_down_dash > ps.dash_cooldown
			):
				previous_down_dash = now
				is_down_dashing = true
				is_actively_jumping = false
				jump_load_start = null
				velocity.y += ps.down_dash_speed
				if ps.unlocked_dash_bullet_time:
					dash_slow_mo()
			if is_down_dashing && now - previous_down_dash > ps.down_dash_duration:
				is_down_dashing = false
				if velocity.y > 0:
					velocity.y -= min(ps.down_dash_speed / 2., velocity.y)
			if ps.unlocked_dash_glide && now - dash_glide_window_start < ps.dash_glide_window:
				if Input.is_action_just_pressed("move_left"):
					velocity.x -= ps.glide_force
					dash_glide_window_start = 0
				elif Input.is_action_just_pressed("move_right"):
					velocity.x += ps.glide_force
					dash_glide_window_start = 0

	# Wall sticking behavior
	if ps.unlocked_wall_climbing:
		if is_on_wall():
			if velocity.y > 0:
				velocity.y -= ps.wall_stickiness * delta
			# Wall jumping
			if (
				Input.is_action_pressed("jump")
				&& (jump_load_start == null || now - jump_load_start > ps.wall_jump_cooldown)
			):
				vt_velocity = -ps.wall_jump_force
				jump_load_start = now

	# Gravity
	hz_velocity = (
		velocity.x - (16 * delta * velocity.x)
		if abs(velocity.x) > abs(hz_velocity)
		else hz_velocity
	)
	var gravity_value = gravity if enable_gravity else 0.0
	velocity = Vector2(hz_velocity, velocity.y + vt_velocity + gravity_value * delta)

	# Billionaire knockback and head bounce
	#if is_in_billionaire:
	if is_on_top_of_billionaire:
		if now - previous_head_bounce > .1:
			if velocity.y > 0:
				velocity.y = -velocity.y / 6.
			else:
				velocity.y = 0
			velocity.y -= ps.billionaire_head_bounce
			if abs(velocity.x) < 500:
				velocity.x = sign(velocity.x) * 500
			previous_head_bounce = now
		#else:
		#var to_billionaire_n = (global_position - _billionaire.global_position).normalized()
		#var knockback = billionaire_knockback * to_billionaire_n
		#if sign(velocity.x) != sign(knockback.x):
		#velocity.x = 0
		#velocity += Vector2(
		#knockback.x if abs(knockback.x) > 100 else sign(knockback.x) * 100, knockback.y
		#)

	velocity = clamp(velocity, Vector2(-8000, -1000), Vector2(8000, 1000))

	if prev_velocity.y > 1000 && is_on_floor():
		_camera.apply_noise_shake()
		dash_glide_window_start = now
		for body in _smash_area.get_overlapping_bodies():
			if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BILLIONAIRE]):
				body.velocity.y -= (
					200 * (1.0 - ((body.global_position - global_position).length() / 250.) ** 2)
				)
				body.spawn_coins(3)
			elif body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.COIN]):
				body.propulse_up(
					1.0 - ((body.global_position - global_position).length() / 250.) ** 3
				)

	prev_velocity = velocity
	move_and_slide()

	# Combat
	_punch_area.scale.x = -1.0 if direction == Direction.LEFT else 1.0

	if Input.is_action_just_pressed("melee") and not is_dead and not is_level_timeout:
		$AttackManager.try_attack()

	# Animation

	# Attack animations are directly handled by the attack manager
	if not is_dead and not $AttackManager.is_attacking():
		if is_on_floor():
			# Ground animations
			if Input.get_axis("move_left", "move_right") == 0:
				$Sprite.play("default")
			else:
				$Sprite.play("walk")
		else:
			# Jump animations
			if velocity.y >= 140 || now - play_jump_start_ts < .05:
				$Sprite.play("jump_end")
			elif velocity.y <= 0:
				$Sprite.play("jump_start")
			else:
				$Sprite.play("jump_middle")


func dash_slow_mo():
	if Globals.create_slowmo(DASH_SLOWMO_NAME, ps.dash_slow_factor):
		await get_tree().create_timer(ps.dash_slow_time).timeout
		Globals.cancel_slowmo_if_exists(DASH_SLOWMO_NAME)


func _exit_tree() -> void:
	Globals.cancel_slowmo_if_exists(DASH_SLOWMO_NAME)
	Globals.cancel_slowmo_if_exists(BULLET_PROXIMITY_SLOWMO_NAME)


func _can_move():
	return not is_level_timeout and not is_dead and not $AttackManager.is_attacking_ground()


func _die():
	$SoundFx/DeathSound.play_sound()
	is_dead = true

	if direction == Direction.LEFT:
		$Sprite.flip_h = false
		direction = Direction.RIGHT
	velocity = Vector2.ZERO

	var slow_factor = 0.7
	$AnimationPlayer.play("die", slow_factor)

	var slowmo_death_routine = func(): await $AnimationPlayer.animation_finished
	# if Globals.create_slowmo("death", dash_slow_factor):
	# 	await $AnimationPlayer.animation_finished
	# Globals.cancel_slowmo_if_exists("death")
	$"../Camera2D".death_zoom()
	_level.on_player_dies(slowmo_death_routine)


func get_hurt(knockback_force):
	if is_dead || is_level_timeout || intouchable:
		return

	# Get knocked back
	velocity += knockback_force
	# Get deformed
	if abs(knockback_force.x) > 1.2 * abs(knockback_force.y):
		scale *= Vector2(1. - clamp((abs(knockback_force.x)) / 2000., 0., .1), 1.)
	elif abs(knockback_force.y) > 1.2 * abs(knockback_force.x):
		scale *= Vector2(1., 1. - clamp((abs(knockback_force.x)) / 2000., 0., .1))
	# Shake
	_camera.apply_noise_shake()
	# Health
	health = health - 1
	_hud.update_life(health)
	if health <= 0:
		_die()
		return
	# Red glow on hit
	_hurt_sound.play()
	modulate = Color(1, 0, 0)
	intouchable = true
	await get_tree().create_timer(1.0).timeout
	intouchable = false
	modulate = Color(1, 1, 1, 1)
	scale = _original_scale


func _on_soft_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Billionaire"):
		is_in_billionaire = true
	elif body is Coin:
		# elif body.is_in_group("coin"):
		_level.on_coin_collected(body.get_collectible_type())
		body.queue_free()


func _on_soft_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Billionaire"):
		is_in_billionaire = false


# When the billionaire is punched from the air, we grant an extra jump to the player (it they are out of jumps)
func _on_attack_manager_punch_has_connected(attack: AttackManager.Attack) -> void:
	emit_signal("billionaire_punched", ps.melee_damage)
	if (
		attack == AttackManager.Attack.AIR
		and ps.unlocked_bonus_jump_after_airhit
		and current_nb_jumps_left == 0
	):
		current_nb_jumps_left += 1


func on_level_timeout():
	is_level_timeout = true


func _on_feet_area_entered(_area: Area2D) -> void:
	is_on_top_of_billionaire = true


func _on_feet_area_exited(_area: Area2D) -> void:
	is_on_top_of_billionaire = false


func _on_bullet_time_area_entered(area: Area2D) -> void:
	if area.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BULLET]):
		bullets_in_proximity.append(area)

		if ps and ps.unlocked_bullet_proximity_slowmo and bullets_in_proximity.size() == 1:
			Globals.create_slowmo(BULLET_PROXIMITY_SLOWMO_NAME, ps.bullet_proximity_slow_factor)


func _on_bullet_time_area_exited(area: Area2D) -> void:
	if area.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BULLET]):
		bullets_in_proximity.erase(area)

		if ps and ps.unlocked_bullet_proximity_slowmo and bullets_in_proximity.is_empty():
			Globals.cancel_slowmo_if_exists(BULLET_PROXIMITY_SLOWMO_NAME)
