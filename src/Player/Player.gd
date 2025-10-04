class_name Player
extends CharacterBody2D

@export var speed = 400
@export var dash_cooldown = 1.0
@export var dash_window = .2
@export var max_input_jump_time = .4
@export var jump_force = 8000

var jump_load_start = null
var is_actively_jumping = false
var previous_left = 0
var previous_right = 0
var previous_dash = 0

@onready var _hurt_sound = $SoundFx/HurtSound
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")

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

	var time_since_jump = now - (jump_load_start if jump_load_start != null else +INF)
	if is_actively_jumping && Input.is_action_pressed("jump") && time_since_jump < max_input_jump_time:
		var timer_proportion = (
			1 - clamp(time_since_jump, 0, max_input_jump_time) / max_input_jump_time
		) ** 4
		vt_velocity = -jump_force * delta * timer_proportion
	elif is_actively_jumping && (time_since_jump > max_input_jump_time || Input.is_action_just_released("jump")):
		is_actively_jumping = false

	# Dashing
	if Input.is_action_just_pressed("move_left"):
		var ts = Time.get_unix_time_from_system()
		if ts - previous_dash > dash_cooldown:
			if ts - previous_left < dash_window:
				previous_dash = ts
				hz_velocity = -3000
			previous_left = ts
	elif Input.is_action_just_pressed("move_right"):
		var ts = Time.get_unix_time_from_system()
		if ts - previous_dash > dash_cooldown:
			if ts - previous_right < dash_window:
				previous_dash = ts
				hz_velocity = 3000
			previous_right = ts
	hz_velocity = (
		velocity.x - (16 * delta * velocity.x)
		if abs(velocity.x) > abs(hz_velocity)
		else hz_velocity
	)
	velocity = Vector2(hz_velocity, velocity.y + vt_velocity + GRAVITY * delta)
	move_and_slide()


func get_hurt():
	# Red glow on hit
	_hurt_sound.play_sound()
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(1.0).timeout
	modulate = Color(1, 1, 1, 1)
