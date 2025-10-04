class_name Player
extends CharacterBody2D

@export var speed = 400
@export var dash_cooldown = 1.0
@export var dash_window = .2

var jump_load_start = null
var is_loading_jump = false
var previous_left = 0
var previous_right = 0
var previous_dash = 0


func _ready() -> void:
	# Waits for Game.gd to run randomize()
	await get_tree().process_frame


func _physics_process(delta):
	var input_direction = Input.get_axis("move_left", "move_right")
	var vt_velocity = 0.
	var hz_velocity = 0.
	# Jumping + walking on floor
	if is_on_floor():
		hz_velocity = input_direction * speed
		# TODO the loaded jumps mechanism is bad
		if !is_loading_jump && Input.is_action_pressed("jump"):
			is_loading_jump = true
			jump_load_start = Time.get_unix_time_from_system()
		elif (
			is_loading_jump
			&& (
				Input.is_action_just_released("jump")
				|| (Time.get_unix_time_from_system() - jump_load_start) > .2
			)
		):
			is_loading_jump = false
			var timer_proportion = (
				.5 + 5. / 2. * clamp(Time.get_unix_time_from_system() - jump_load_start, 0, .2)
			)
			vt_velocity = - speed * timer_proportion
	else:
		is_loading_jump = false
		hz_velocity = velocity.x - (.1 * delta * velocity.x)
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
	velocity = Vector2(hz_velocity, velocity.y + vt_velocity + 980 * delta)
	move_and_slide()
