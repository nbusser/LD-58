extends Node2D

@onready var laser_surface: Polygon2D = $LaserSurface

var time: float = 0.0
var laser_positions: PackedVector2Array
var laser_states: PackedFloat32Array

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

	laser_positions.resize(16)
	laser_states.resize(8)

func _on_viewport_size_changed():
	var viewport_size: Vector2i = get_viewport().size
	if laser_surface:
		laser_surface.scale = viewport_size
		laser_surface.material.set_shader_parameter("resolution", viewport_size * .5)

func _process(delta):
	time += delta

	var laser_count = 4

	# laser_positions[0] = Vector2(0.1 + sin(time * 1.5) * 0.05, 0.0)
	laser_positions[0] = Vector2(0.1, 0.0)
	laser_positions[1] = Vector2(0.15 + sin(time * 1.2) * 0.1, 1.0)

	laser_positions[2] = Vector2(0.8, 0.0)
	laser_positions[3] = Vector2(0.85 + cos(time * 1.0) * 0.05, 1.0)

	laser_positions[4] = Vector2(0.0, 0.3 + sin(time * 2.0) * 0.2)
	laser_positions[5] = Vector2(1.0, 0.4 + sin(time * 1.8) * 0.15)

	laser_positions[6] = Vector2(0.5 + sin(time * 0.7) * 0.3, 0.0)
	laser_positions[7] = Vector2(0.5 + cos(time * 0.9) * 0.2, 1.0)
	
	# Animate laser states
	# Laser 0: cycles through warning phase
	laser_states[0] = fmod(time * 0.5, 1.0)
	
	# Laser 1: always active
	laser_states[1] = 1.0
	
	# Laser 2: cycles through full lifecycle (warning -> active -> dying)
	laser_states[2] = fmod(time * 0.3, 2.0)
	
	# Laser 3: pulses between active and dying
	laser_states[3] = 1.0 + abs(sin(time * 2.0)) * 0.5

	laser_surface.material.set_shader_parameter("laser_count", laser_count)
	laser_surface.material.set_shader_parameter("laser_points", laser_positions)
	laser_surface.material.set_shader_parameter("laser_states", laser_states)

	var hue = fmod(time * 20.0, 360.0)
	laser_surface.material.set_shader_parameter("laser_hue", hue)
