class_name Player
extends CharacterBody2D

signal billionaire_punched(damage: int)

const DIRECTIONS = ["move_left", "move_right"]
const DIRECTIONS_MODIFIERS = [-1, 1]

# Movement
@export var ground_speed = 450
@export var air_speed = 300
# Horizontal dash
@export var dash_cooldown = 1.0
@export var dash_speed = 3000
@export var dash_window = .2
# Vertical dash
@export var down_dash_speed = 1600
@export var down_dash_duration = 0.08
# Jumps
@export var max_input_jump_time = .4
@export var jump_force = 8000
# Billionaire contact
@export var billionaire_head_bounce = 450
@export var billionaire_knockback = 450
# Combat
@export var melee_damage = 100
@export var melee_cooldown = .3
@export var melee_duration = .1
@export var is_melee_one_shot = true

var jump_load_start = null
var is_actively_jumping = false
var is_down_dashing = false
var can_down_dash = false
var is_in_billionaire = false
var is_on_top_of_billionaire = false
var billionaire_in_melee_reach = false
var in_melee = false

var previous_dir = [0, 0]  # left, right
var previous_dash = 0
var previous_down_dash = 0
var previous_melee = 0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var _hurt_sound = $SoundFx/HurtSound
@onready var _billionaire: CharacterBody2D = $"../Billionaire/BillionaireBody"
@onready var _punch_area: Area2D = $PunchArea
@onready var _hud: HUD = $"../../UI/HUD"
@onready var _level: Node = $"../.."


func _ready() -> void:
	# Waits for Game.gd to run randomize()
	await get_tree().process_frame


func _physics_process(delta):
	var vt_velocity = 0.
	var hz_velocity = 0.
	var now = Time.get_unix_time_from_system()

	# Horizontal movement
	var input_direction = Input.get_axis("move_left", "move_right")
	hz_velocity = input_direction * (ground_speed if self.is_on_floor() else air_speed)
	if is_on_floor() && !is_actively_jumping && Input.is_action_pressed("jump"):
		is_actively_jumping = true
		jump_load_start = now

	# Jump
	var time_since_jump = now - (jump_load_start if jump_load_start != null else INF)
	if (
		is_actively_jumping
		&& Input.is_action_pressed("jump")
		&& time_since_jump < max_input_jump_time
	):
		var timer_proportion = (
			(1 - clamp(time_since_jump, 0, max_input_jump_time) / max_input_jump_time) ** 4
		)
		vt_velocity = -jump_force * delta * timer_proportion
	elif (
		is_actively_jumping
		&& (time_since_jump > max_input_jump_time || Input.is_action_just_released("jump"))
	):
		is_actively_jumping = false

	# Horizontal dash
	for dir in range(2):
		if Input.is_action_just_pressed(DIRECTIONS[dir]):
			if now - previous_dash > dash_cooldown:
				if now - previous_dir[dir] < dash_window:
					previous_dash = now
					hz_velocity = DIRECTIONS_MODIFIERS[dir] * dash_speed
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
	if is_down_dashing && now - previous_down_dash > down_dash_duration:
		is_down_dashing = false
		velocity.y -= down_dash_speed

	hz_velocity = (
		velocity.x - (16 * delta * velocity.x)
		if abs(velocity.x) > abs(hz_velocity)
		else hz_velocity
	)
	velocity = Vector2(hz_velocity, velocity.y + vt_velocity + gravity * delta)

	# Billionaire knockback and head bounce
	if is_in_billionaire:
		if is_on_top_of_billionaire:
			velocity.y = -billionaire_head_bounce
		else:
			var to_billionaire_n = (global_position - _billionaire.global_position).normalized()
			var knockback = billionaire_knockback * to_billionaire_n
			if sign(velocity.x) != sign(knockback.x):
				velocity.x = 0
			velocity += Vector2(
				knockback.x if abs(knockback.x) > 100 else sign(knockback.x) * 100, knockback.y
			)

	velocity = clamp(velocity, Vector2(-3000, -600), Vector2(3000, 600))

	move_and_slide()

	# Combat
	if velocity.x > 0:
		_punch_area.scale.x = 1.0
	elif velocity.x < 0:
		_punch_area.scale.x = -1.0
	if Input.is_action_just_pressed("melee") && now - previous_melee > melee_cooldown:
		in_melee = true
	elif (
		in_melee && (Input.is_action_just_pressed("melee") || now - previous_melee > melee_duration)
	):
		in_melee = false
	if in_melee && billionaire_in_melee_reach:
		emit_signal("billionaire_punched", melee_damage)
		if is_melee_one_shot:
			in_melee = false


func get_hurt(knockback_force):
	# Get knocked back
	velocity += knockback_force
	# Get deformed
	scale = Vector2(
		(1. - clamp((abs(knockback_force.x)) / 2000., 0., .2)) * .24,
		(1. - clamp((abs(knockback_force.y)) / 2000., 0., .2)) * .24
	)
	print(scale)
	print(knockback_force)
	# Red glow on hit
	_hurt_sound.play_sound()
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(1.0).timeout
	modulate = Color(1, 1, 1, 1)
	scale = Vector2(.24, .24)


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


func _on_punch_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Billionaire"):
		billionaire_in_melee_reach = true


func _on_punch_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Billionaire"):
		billionaire_in_melee_reach = false
