extends Node2D

var laser_positions: PackedVector2Array
var laser_states: PackedFloat32Array
var active_lasers: Array[Dictionary] = []
const max_lasers: int = 12
const laser_size = 50.0

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var laser_surface: ColorRect = get_tree().get_first_node_in_group("laser_surface")
@onready var ground = $"../Borders/Ground/CollisionShape2D"
@onready var ceiling = $"../Borders/Ceiling/CollisionShape2D"
@onready var wall_l = $"../Borders/WallL/CamMarker"
@onready var wall_r = $"../Borders/WallR/CamMarker"

var limits: Rect2 = Rect2()


func _ready():
	laser_positions.resize(max_lasers * 2)
	laser_states.resize(max_lasers)

	for i in range(8):
		laser_states[i] = 2.0  # All off initially

	# Set up limits based on level boundaries
	if wall_l and wall_r and ground and ceiling:
		limits.position.x = wall_l.global_position.x
		limits.position.y = ceiling.global_position.y
		limits.size.x = wall_r.global_position.x - wall_l.global_position.x
		limits.size.y = ground.global_position.y - ceiling.global_position.y
	else:
		# Fallback to viewport if boundaries not found
		var viewport_size = get_viewport().size
		limits = Rect2(Vector2(-viewport_size.x / 2, -viewport_size.y / 2), viewport_size)

	setup_laser_surface()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()


func setup_laser_surface():
	laser_surface.material.set_shader_parameter("laser_hue", 15.0)


func _on_viewport_size_changed():
	var viewport_size = get_viewport().size
	if laser_surface:
		laser_surface.material.set_shader_parameter("resolution", viewport_size)


const progress_before_flash = 0.62
const progress_flash = 0.8


func _physics_process(delta):
	var i = 0
	for laser in active_lasers:
		if i >= max_lasers:
			print("Max lasers reached, skipping additional lasers", i)
			break

		laser.timer += delta

		# Update positions
		if laser.has("update_func"):
			laser.update_func.call(laser, delta)

		laser_positions[i * 2] = laser.start
		laser_positions[i * 2 + 1] = laser.end

		var laser_progress = laser.timer / laser.warning_duration
		# Update state based on timer
		if laser_progress < progress_before_flash:
			laser_states[i] = laser_progress
		elif laser_progress < progress_flash:
			laser_states[i] = laser_progress

			var length = laser.start.distance_to(laser.end)
			var dir = (laser.end - laser.start).normalized()
			# stretch the laser
			var progress = clamp(
				(laser_progress - progress_before_flash) / (progress_flash - progress_before_flash),
				0.0,
				1.0
			)
			laser_positions[i * 2 + 1] = laser.start + dir * length * progress
		elif laser_progress < 1.0:
			laser_states[i] = laser_progress
		elif laser.timer < laser.warning_duration + laser.active_duration:
			laser_states[i] = 1.0
			# Check collision with player during active phase
			if not laser.has_hit and is_laser_hitting_player(laser.start, laser.end):
				player.get_hurt(Vector2.ZERO)
				laser.has_hit = true
		else:
			var fade_time = laser.timer - (laser.warning_duration + laser.active_duration)
			var progress = fade_time * 4.
			laser_states[i] = 1.0 + progress

			var length = laser.start.distance_to(laser.end)
			var dir = (laser.end - laser.start).normalized()
			laser_positions[i * 2] = laser.start + dir * length * min(progress, 1.0)

			if progress > 1.0:
				laser.finished = true
		i += 1

	# Clear finished lasers
	active_lasers = active_lasers.filter(func(l): return not l.get("finished", false))

	# Clear unused laser slots
	for j in range(i, max_lasers):
		laser_states[j] = 2.0


func _process(_delta):
	update_shader_parameters()


func update_shader_parameters():
	if not laser_surface:
		return

	var screen_transform = get_viewport().canvas_transform
	var screen_size = get_viewport().size

	var converted_positions = PackedVector2Array()
	for i in range(laser_positions.size()):
		var p = laser_positions[i]
		converted_positions.append(screen_transform * p / Vector2(screen_size))

	var active_count = min(active_lasers.size(), max_lasers)
	laser_surface.material.set_shader_parameter("laser_count", active_count)
	laser_surface.material.set_shader_parameter("laser_points", converted_positions)
	laser_surface.material.set_shader_parameter("laser_states", laser_states)


func is_laser_hitting_player(start: Vector2, end: Vector2) -> bool:
	# start and end are already in world coordinates
	var player_pos = player.global_position

	# Calculate distance from player to laser line
	var pa = player_pos - start
	var ba = end - start
	var t = clamp(pa.dot(ba) / ba.dot(ba), 0.0, 1.0)
	var closest_point = start + t * ba
	var distance = player_pos.distance_to(closest_point)

	# Check if player is within laser beam (adjust threshold as needed)
	return distance < 30.0


func add_laser(
	start: Vector2, end: Vector2, warning_duration: float = 1.0, active_duration: float = 2.0
) -> Dictionary:
	var laser = {
		"start": start,
		"end": end,
		"warning_duration": warning_duration,
		"active_duration": active_duration,
		"timer": 0.0,
		"has_hit": false,
		"finished": false
	}
	active_lasers.append(laser)
	return laser


func clear_all_lasers():
	active_lasers.clear()
	for i in range(max_lasers):
		laser_states[i] = 2.0


# Attack pattern: Warning lasers at player position
func laser_warning_pattern(num_lasers: int = 3, delay_between: float = 0.3):
	var base_x = player.global_position.x
	if player.velocity.x != 0:
		base_x += player.velocity.x * 0.3  # Predict ~0.3 seconds ahead
	base_x = base_x + randf_range(-150.0, -50.0)
	base_x = clamp(
		base_x, limits.position.x + laser_size, limits.position.x + limits.size.x - laser_size
	)
	var interval = randf_range(80.0, 150.0)
	for i in range(num_lasers):
		var x = base_x + i * interval
		if x < limits.position.x + laser_size or x > limits.position.x + limits.size.x - laser_size:
			continue  # Skip lasers outside limits

		add_laser(
			Vector2(x, limits.position.y), Vector2(x, limits.position.y + limits.size.y), 2.0, 1.0
		)
		await get_tree().create_timer(delay_between).timeout


# Attack pattern: Sweep across screen
func laser_sweep_pattern(direction: int = 1, speed: float = 200.0):
	var start_x = (
		limits.position.x + 50 if direction > 0 else limits.position.x + limits.size.x - 50
	)
	var laser = add_laser(
		Vector2(start_x, limits.position.y),
		Vector2(start_x, limits.position.y + limits.size.y),
		0.8,
		3.0
	)

	laser.update_func = func(l: Dictionary, delta: float):
		var new_x = l.start.x + direction * speed * delta
		new_x = clamp(new_x, limits.position.x + 30, limits.position.x + limits.size.x - 30)
		l.start.x = new_x
		l.end.x = new_x


# Attack pattern: Laser cage around player
func laser_cage_pattern():
	var player_x = player.global_position.x
	player_x = clamp(player_x, limits.position.x + 200, limits.position.x + limits.size.x - 200)

	# Left wall
	add_laser(
		Vector2(player_x - 150, limits.position.y),
		Vector2(player_x - 150, limits.position.y + limits.size.y),
		2.0,
		2.5
	)
	# Right wall
	add_laser(
		Vector2(player_x + 150, limits.position.y),
		Vector2(player_x + 150, limits.position.y + limits.size.y),
		2.0,
		2.5
	)

	await get_tree().create_timer(1.5).timeout

	# Closing walls
	var left_laser = add_laser(
		Vector2(player_x - 300, limits.position.y),
		Vector2(player_x - 300, limits.position.y + limits.size.y),
		1.0,
		2.0
	)
	var right_laser = add_laser(
		Vector2(player_x + 300, limits.position.y),
		Vector2(player_x + 300, limits.position.y + limits.size.y),
		1.0,
		2.0
	)

	var close_speed = 100.0
	var update_closing = func(l: Dictionary, delta: float):
		if l == left_laser:
			l.start.x = min(l.start.x + close_speed * delta, player_x - 50)
			l.end.x = l.start.x
		else:
			l.start.x = max(l.start.x - close_speed * delta, player_x + 50)
			l.end.x = l.start.x

	left_laser.update_func = update_closing
	right_laser.update_func = update_closing
