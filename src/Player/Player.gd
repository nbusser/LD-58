class_name Player
extends CharacterBody2D

signal billionaire_punched(damage: int)

enum Direction { LEFT = -1, RIGHT = 1 }

const DIRECTIONS = ["move_left", "move_right"]
const DIRECTIONS_MODIFIERS = [-1, 1]
const DASH_SLOWMO_NAME := "player_dash"

# Movement
@export var ground_speed = 300
@export var air_speed = 240
# Horizontal dash
@export var dash_cooldown = 1.0
@export var dash_speed = 2000
@export var dash_window = .2
# Dash slow motion
@export var dash_slow_factor = 0.6
@export var dash_slow_time = 0.3
# Vertical dash
@export var down_dash_speed = 1000
@export var down_dash_duration = 0.08
# Jumps
@export var max_input_jump_time = .4
@export var jump_force = 6000
# Walls stickiness
@export var wall_stickiness = 500
@export var wall_jump_force = 450
@export var wall_jump_cooldown = .7
# Billionaire contact
@export var billionaire_head_bounce = 250
@export var billionaire_knockback = 800
# Combat
@export var melee_damage = 100
@export var melee_cooldown = .3
@export var melee_duration = .1
@export var is_melee_one_shot = true

var jump_load_start = null
var is_actively_jumping = false
var is_keep_pressing_jump_button = false
var is_down_dashing = false
var can_down_dash = false
var is_in_billionaire = false
var is_on_top_of_billionaire = false

var direction = Direction.RIGHT

var previous_dir = [0, 0]  # left, right
var previous_dash = 0
var previous_down_dash = 0
var previous_melee = 0
var previous_head_bounce = 0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_nb_jumps = 0
var max_nb_jumps = 2

var prev_velocity = Vector2(0, 0)

@onready var _hurt_sound = $SoundFx/HurtSound
@onready var _billionaire: CharacterBody2D = $"../Billionaire/BillionaireBody"
@onready var _punch_area: Area2D = $PunchArea
@onready var _smash_area: Area2D = $SmashArea
@onready var _hud: HUD = $"../../UI/HUD"
@onready var _level: Node = $"../.."
@onready var _camera: Node = $"../Camera2D"
@onready var _original_scale = scale


func _ready() -> void:
	# Waits for Game.gd to run randomize()
	await get_tree().process_frame


func _physics_process(delta):
	var vt_velocity = 0.
	var hz_velocity = 0.
	var now = Time.get_unix_time_from_system()

	if is_on_floor():
		current_nb_jumps = 0

	if _can_move():
		# Horizontal movement
		var input_direction = Input.get_axis("move_left", "move_right")
		if input_direction != 0:
			direction = Direction.LEFT if input_direction == -1 else Direction.RIGHT

		($Sprite as AnimatedSprite2D).flip_h = direction == Direction.LEFT

		hz_velocity = input_direction * (ground_speed if self.is_on_floor() else air_speed)
		if (
			not is_keep_pressing_jump_button  # No automatic jump when space is kept pressed
			and current_nb_jumps < max_nb_jumps  # As long as we have remaining jumps
			and Input.is_action_pressed("jump")
		):
			# Cleans up gravity
			velocity.y = 0
			current_nb_jumps += 1
			is_actively_jumping = true
			jump_load_start = now

		# Jump
		var time_since_jump = now - (jump_load_start if jump_load_start != null else INF)
		if (
			is_actively_jumping
			&& Input.is_action_pressed("jump")
			&& time_since_jump < max_input_jump_time
		):
			is_keep_pressing_jump_button = true
			var timer_proportion = (
				(1 - clamp(time_since_jump, 0, max_input_jump_time) / max_input_jump_time) ** 4
			)
			vt_velocity = -jump_force * delta * timer_proportion
		elif (
			is_actively_jumping
			&& (time_since_jump > max_input_jump_time || Input.is_action_just_released("jump"))
		):
			is_actively_jumping = false

		if Input.is_action_just_released("jump"):
			is_keep_pressing_jump_button = false

		# Horizontal dash
		for dir in range(2):
			if Input.is_action_just_pressed(DIRECTIONS[dir]):
				if now - previous_dash > dash_cooldown:
					if now - previous_dir[dir] < dash_window:
						previous_dash = now
						hz_velocity = DIRECTIONS_MODIFIERS[dir] * dash_speed
						dash_slow_mo()
					previous_dir[dir] = now
		_hud.set_dash_cooldown(100. * clamp((now - previous_dash) / dash_cooldown, 0., 100.))

		# Down dash
		if is_on_floor():
			can_down_dash = true
			is_down_dashing = false

		if (
			Input.is_action_just_pressed("dash_down")
			&& can_down_dash
			&& !is_on_floor()
			&& !is_down_dashing
			&& now - previous_down_dash > dash_cooldown
		):
			previous_down_dash = now
			is_down_dashing = true
			is_actively_jumping = false
			jump_load_start = null
			velocity.y += down_dash_speed
			dash_slow_mo()
		if is_down_dashing && now - previous_down_dash > down_dash_duration:
			is_down_dashing = false
			if velocity.y > 0:
				velocity.y -= min(down_dash_speed / 2., velocity.y)

	# Wall sticking behavior
	if is_on_wall():
		if velocity.y > 0:
			velocity.y -= wall_stickiness * delta
		# Wall jumping
		if (
			Input.is_action_pressed("jump")
			&& (jump_load_start == null || now - jump_load_start > wall_jump_cooldown)
		):
			vt_velocity = -wall_jump_force
			jump_load_start = now

	hz_velocity = (
		velocity.x - (16 * delta * velocity.x)
		if abs(velocity.x) > abs(hz_velocity)
		else hz_velocity
	)
	velocity = Vector2(hz_velocity, velocity.y + vt_velocity + gravity * delta)

	# Billionaire knockback and head bounce
	if is_in_billionaire:
		if is_on_top_of_billionaire:
			if now - previous_head_bounce > .1:
				if velocity.y > 0:
					velocity.y = -velocity.y / 6.
				else:
					velocity.y = 0
				velocity.y -= billionaire_head_bounce
				previous_head_bounce = now
		else:
			var to_billionaire_n = (global_position - _billionaire.global_position).normalized()
			var knockback = billionaire_knockback * to_billionaire_n
			if sign(velocity.x) != sign(knockback.x):
				velocity.x = 0
			velocity += Vector2(
				knockback.x if abs(knockback.x) > 100 else sign(knockback.x) * 100, knockback.y
			)

	velocity = clamp(velocity, Vector2(-3000, -600), Vector2(3000, 600))

	if prev_velocity.y > 1000 && is_on_floor():
		_camera.apply_noise_shake()
		for body in _smash_area.get_overlapping_bodies():
			if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BILLIONAIRE]):
				body.velocity.y -= (
					200 * (1.0 - ((body.global_position - global_position).length() / 100.) ** 2)
				)
			elif body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.COIN]):
				body.propulse_up(
					1.0 - ((body.global_position - global_position).length() / 100.) ** 2
				)

	prev_velocity = velocity
	move_and_slide()

	# Combat
	_punch_area.scale.x = -1.0 if direction == Direction.LEFT else 1.0

	if Input.is_action_just_pressed("melee"):
		$AttackManager.try_attack()

	# Animation

	# Attack animations are directly handled by the attack manager
	if not $AttackManager.is_attacking():
		if is_on_floor():
			# Ground animations
			if Input.get_axis("move_left", "move_right") == 0:
				$Sprite.play("default")
			else:
				$Sprite.play("walk")
		else:
			# Jump animations
			if velocity.y <= 0:
				$Sprite.play("jump_start")
			elif velocity.y < 140:
				$Sprite.play("jump_middle")
			else:
				$Sprite.play("jump_end")


func dash_slow_mo():
	if Globals.create_slowmo(DASH_SLOWMO_NAME, dash_slow_factor):
		await get_tree().create_timer(dash_slow_time).timeout
		Globals.cancel_slowmo_if_exists(DASH_SLOWMO_NAME)


func _exit_tree() -> void:
	Globals.cancel_slowmo_if_exists(DASH_SLOWMO_NAME)


func _can_move():
	return not $AttackManager.is_attacking_ground()


func get_hurt(knockback_force):
	# Get knocked back
	velocity += knockback_force
	# Get deformed
	scale *= Vector2(
		1. - clamp((abs(knockback_force.x)) / 2000., 0., .2),
		1. - clamp((abs(knockback_force.y)) / 2000., 0., .2)
	)
	_camera.apply_noise_shake()

	# Red glow on hit
	_hurt_sound.play_sound()
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(1.0).timeout
	modulate = Color(1, 1, 1, 1)
	scale = _original_scale


func _on_soft_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Billionaire"):
		is_in_billionaire = true
	elif body.is_in_group("coin"):
		body.queue_free()
		_level.on_coin_collected()


func _on_soft_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Billionaire"):
		is_in_billionaire = false


func _on_feet_body_entered(_body: Node2D) -> void:
	is_on_top_of_billionaire = true


func _on_feet_body_exited(_body: Node2D) -> void:
	is_on_top_of_billionaire = false
