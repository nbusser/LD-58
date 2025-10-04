class_name Player
extends CharacterBody2D

signal billionaire_punched(damage: int)

const DIRECTIONS = ["move_left", "move_right"]
const DIRECTIONS_MODIFIERS = [-1, 1]

@export var speed = 400
@export var dash_cooldown = 1.0
@export var dash_window = .2
@export var max_input_jump_time = .4
@export var jump_force = 8000
@export var down_dash_speed = 1600
@export var down_dash_duration = 0.08
@export var punch_damage = 100

var jump_load_start = null
var is_actively_jumping = false
var is_down_dashing = false
var can_down_dash = false

var previous_dir = [0, 0]  # left, right
var previous_dash = 0
var previous_down_dash = 0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var _hurt_sound = $SoundFx/HurtSound


func _ready() -> void:
	# Waits for Game.gd to run randomize()
	await get_tree().process_frame


func _physics_process(delta):
	var input_direction = Input.get_axis("move_left", "move_right")
	var vt_velocity = 0.
	var hz_velocity = 0.

	# Jumping + walking on floor
	var now = Time.get_unix_time_from_system()
	hz_velocity = input_direction * speed
	if is_on_floor() && !is_actively_jumping && Input.is_action_pressed("jump"):
		is_actively_jumping = true
		jump_load_start = now

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

	# Dashing
	for dir in range(2):
		if Input.is_action_just_pressed(DIRECTIONS[dir]):
			if now - previous_dash > dash_cooldown:
				if now - previous_dir[dir] < dash_window:
					previous_dash = now
					hz_velocity = DIRECTIONS_MODIFIERS[dir] * 3000
				previous_dir[dir] = now

	# Down dashing
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
	velocity.y = clamp(velocity.y, -300, 300)
	move_and_slide()


func get_hurt():
	# Red glow on hit
	_hurt_sound.play_sound()
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(1.0).timeout
	modulate = Color(1, 1, 1, 1)


func _on_punch_area_area_entered(area):
	if area.is_in_group("billionaire"):
		emit_signal("billionaire_punched", punch_damage)


func _on_soft_hitbox_body_entered(body: Node2D) -> void:
	var to_billionaire = global_position - body.global_position
	var base_punch = 1500*to_billionaire.normalized()
	velocity += Vector2(base_punch.x, base_punch.y)
