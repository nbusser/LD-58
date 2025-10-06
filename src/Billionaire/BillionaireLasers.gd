extends Node2D

var max_lasers: int = 12
var laser_size = 50.0

var progress_before_flash = 0.62
var progress_flash = 0.8

var laser_positions: PackedVector2Array
var laser_states: PackedFloat32Array
var active_lasers: Array[Dictionary] = []
var limits: Rect2 = Rect2()

var focus_sounds: Array[AudioStreamPlayer2D] = []
var beam_sounds: Array[AudioStreamPlayer2D] = []
var focus_audio_streams: Array[AudioStream] = []
var beam_audio_streams: Array[AudioStream] = []
var laser_areas: Array[Area2D] = []
var laser_collision_shapes: Array[CollisionShape2D] = []

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var laser_surface: ColorRect = get_tree().get_first_node_in_group("laser_surface")
@onready var ground = $"../Borders/Ground/CollisionShape2D"
@onready var ceiling = $"../Borders/Ceiling/CollisionShape2D"
@onready var wall_l = $"../Borders/WallL/CamMarker"
@onready var wall_r = $"../Borders/WallR/CamMarker"


func _ready():
	laser_positions.resize(max_lasers * 2)
	laser_states.resize(max_lasers)

	for i in range(8):
		laser_states[i] = 2.0  # All off initially

	# Load audio streams
	for i in range(1, 6):
		var path = "res://assets/sounds/laser_focus/focus_var_0%d.ogg" % i
		focus_audio_streams.append(load(path))

	for i in range(3):
		var path = "res://assets/sounds/laser_beam/beam_%d.ogg" % i
		beam_audio_streams.append(load(path))

	# Create audio players and collision areas for each laser slot
	for i in range(max_lasers):
		var focus_player = AudioStreamPlayer2D.new()
		focus_player.name = "FocusSound%d" % i
		focus_player.bus = "SFX"
		focus_player.max_distance = 1500
		add_child(focus_player)
		focus_sounds.append(focus_player)

		var beam_player = AudioStreamPlayer2D.new()
		beam_player.name = "BeamSound%d" % i
		beam_player.bus = "SFX"
		beam_player.max_distance = 1500
		add_child(beam_player)
		beam_sounds.append(beam_player)

		# Create Area2D for laser collision
		var area = Area2D.new()
		area.name = "LaserArea%d" % i
		area.collision_layer = 0  # Don't collide with anything
		area.collision_mask = 1 << 4  # Collide with player layer 5
		area.monitoring = false  # Start disabled
		add_child(area)

		# Create collision shape
		var collision_shape = CollisionShape2D.new()
		collision_shape.name = "LaserCollision%d" % i
		var rect = RectangleShape2D.new()
		rect.size = Vector2(30, 100)  # Will be adjusted dynamically
		collision_shape.shape = rect
		collision_shape.disabled = true
		area.add_child(collision_shape)

		# Connect collision signal
		area.body_entered.connect(_on_laser_hit_player.bind(i))

		laser_areas.append(area)
		laser_collision_shapes.append(collision_shape)

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


func _physics_process(delta):
	var i = 0
	for laser in active_lasers:
		if i >= max_lasers:
			print("Max lasers reached, skipping additional lasers", i)
			break

		var prev_timer = laser.timer
		laser.timer += delta

		# Update positions
		if laser.has("update_func"):
			laser.update_func.call(laser, delta)

		laser_positions[i * 2] = laser.start
		laser_positions[i * 2 + 1] = laser.end

		# Update sound positions
		if i < focus_sounds.size():
			focus_sounds[i].global_position = laser.start
		if i < beam_sounds.size():
			var center = (laser.start + laser.end) / 2.0
			beam_sounds[i].global_position = center

		# Update collision shape position and size
		if i < laser_areas.size() and i < laser_collision_shapes.size():
			var area = laser_areas[i]
			var collision_shape = laser_collision_shapes[i]
			var center = (laser.start + laser.end) / 2.0
			var length = laser.start.distance_to(laser.end)
			var angle = (laser.end - laser.start).angle()

			area.global_position = center
			area.rotation = angle

			if collision_shape.shape is RectangleShape2D:
				collision_shape.shape.size = Vector2(length, 30)  # 30 pixels wide laser

		var laser_progress = laser.timer / laser.warning_duration
		# Update state based on timer
		if laser_progress < progress_before_flash:
			laser_states[i] = laser_progress
			# Play focus sound at the beginning of warning
			if prev_timer == 0 and not laser.get("focus_played", false):
				if i < focus_sounds.size() and focus_audio_streams.size() > 0:
					focus_sounds[i].stream = focus_audio_streams[
						randi() % focus_audio_streams.size()
					]
					focus_sounds[i].play()
					laser.focus_played = true
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
			# Play beam sound when laser becomes active
			if prev_timer < laser.warning_duration and not laser.get("beam_played", false):
				if i < beam_sounds.size() and beam_audio_streams.size() > 0:
					beam_sounds[i].stream = beam_audio_streams[randi() % beam_audio_streams.size()]
					beam_sounds[i].play()
					laser.beam_played = true
				# Enable collision detection
				if i < laser_areas.size() and i < laser_collision_shapes.size():
					laser_areas[i].monitoring = true
					laser_collision_shapes[i].disabled = false
					laser.laser_index = i
		else:
			var fade_time = laser.timer - (laser.warning_duration + laser.active_duration)
			var progress = fade_time * 4.
			laser_states[i] = 1.0 + progress

			var length = laser.start.distance_to(laser.end)
			var dir = (laser.end - laser.start).normalized()
			laser_positions[i * 2] = laser.start + dir * length * min(progress, 1.0)

			if progress > 1.0:
				laser.finished = true
				# Stop sounds and disable collision when laser finishes
				if i < focus_sounds.size() and focus_sounds[i].playing:
					focus_sounds[i].stop()
				if i < beam_sounds.size() and beam_sounds[i].playing:
					beam_sounds[i].stop()
				if i < laser_areas.size() and i < laser_collision_shapes.size():
					laser_areas[i].monitoring = false
					laser_collision_shapes[i].disabled = true
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


func _on_laser_hit_player(body: Node, laser_index: int) -> void:
	if body == player:
		# Find the laser by its index
		var matching_laser = null
		var current_index = 0
		for laser in active_lasers:
			if current_index == laser_index:
				matching_laser = laser
				break
			current_index += 1

		if matching_laser and not matching_laser.get("has_hit", false):
			# Calculate bounce direction perpendicular to laser
			var laser_dir = (matching_laser.end - matching_laser.start).normalized()
			var to_player = player.global_position - matching_laser.start
			var distance_along_laser = to_player.dot(laser_dir)
			var closest_point = matching_laser.start + laser_dir * distance_along_laser
			var bounce_dir = (player.global_position - closest_point).normalized()

			# Apply bounce force and damage
			player.get_hurt(Vector2(1200 * sign(bounce_dir.x), -100))
			matching_laser.has_hit = true

			# Brief invulnerability to prevent multi-hit
			await get_tree().create_timer(0.5).timeout
			if matching_laser:
				matching_laser.has_hit = false


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
		# Stop all sounds and disable collisions
		if i < focus_sounds.size() and focus_sounds[i].playing:
			focus_sounds[i].stop()
		if i < beam_sounds.size() and beam_sounds[i].playing:
			beam_sounds[i].stop()
		if i < laser_areas.size():
			laser_areas[i].monitoring = false
		if i < laser_collision_shapes.size():
			laser_collision_shapes[i].disabled = true


# Attack pattern: Warning lasers at player position
func laser_warning_pattern(num_lasers: int = 3, delay_between: float = 0.3):
	var base_x = player.global_position.x
	var dir = sign(player.velocity.x)
	if dir == 0:
		dir = 1 if randf() < 0.5 else -1
	# Predictive aiming based on player velocity
	if player.velocity.x != 0:
		base_x += player.velocity.x * 0.3  # Predict ~0.3 seconds ahead
	base_x = base_x + randf_range(-150.0, -50.0) * dir
	base_x = clamp(
		base_x, limits.position.x + laser_size, limits.position.x + limits.size.x - laser_size
	)
	var interval = randf_range(80.0, 150.0)
	for i in range(num_lasers):
		var x = base_x + i * interval * dir
		# Ensure lasers are within limits
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
