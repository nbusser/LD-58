extends Camera2D

# Screen shaking effect adapted from
# https://shaggydev.com/2022/02/23/screen-shake-godot/
# How quickly to move through the noise
@export var noise_shake_speed: float = 30.0
# Noise returns values in the range (-1, 1)
# So this is how much to multiply the returned value by
@export var noise_shake_strength: float = 60.0
# Multiplier for lerping the shake strength to zero
@export var shake_decay_rate: float = 5.0

@export var noise_bg_shake_speed = 2
@export var noise_bg_shake_strength = 30.0

# Used to keep track of where we are in the noise
# so that we can smoothly move through it
var noise_i: float = 0.0
var noise_bg_i: float = 0.0

var shake_strength: float = 0.0

@onready var player = $"../Player"
@onready var billionaire = $"../Billionaire/BillionaireBody"
@onready var boss_indicator = $"../BossIndicator"
@onready var rand = RandomNumberGenerator.new()
@onready var noise = FastNoiseLite.new()
@onready var noise_bg = FastNoiseLite.new()

@onready var ground = $"../Borders/Ground/CollisionShape2D"
@onready var ceiling = $"../Borders/Ceiling/CollisionShape2D"
@onready var wall_l = $"../Borders/WallL/CamMarker"
@onready var wall_r = $"../Borders/WallR/CamMarker"


func _ready() -> void:
	rand.randomize()
	# Randomize the generated noise
	noise.seed = rand.randi()
	noise_bg.seed = rand.randi()
	# Period affects how quickly the noise changes values
	noise.frequency = 0.2
	apply_noise_shake()
	limit_left = wall_l.global_position.x
	limit_right = wall_r.global_position.x
	limit_top = ceiling.global_position.y
	limit_bottom = ground.global_position.y + 25
	zoom = Vector2(1., 1.)


func apply_noise_shake() -> void:
	shake_strength = noise_shake_strength


func get_noise_offset(delta: float) -> Vector2:
	noise_i += delta * noise_shake_speed
	noise_bg_i += delta * noise_bg_shake_speed
	# Set the x values of each call to 'get_noise_2d' to a different value
	# so that our x and y vectors will be reading from unrelated areas of noise
	return Vector2(
		(
			noise.get_noise_2d(1, noise_i) * shake_strength
			+ noise_bg.get_noise_2d(1, noise_bg_i) * noise_bg_shake_strength
		),
		(
			noise.get_noise_2d(100, noise_i) * shake_strength
			+ noise_bg.get_noise_2d(100, noise_bg_i) * noise_bg_shake_strength
		)
	)


func get_camera_rect() -> Rect2:
	var camera_center = get_screen_center_position()
	var screen_size = get_viewport().get_visible_rect().size
	screen_size = (screen_size / zoom) / 2
	var rec = Rect2(camera_center - screen_size, 2 * screen_size)
	return rec


func collision(r: Rect2, l_to: Vector2) -> Variant:
	var l_from = r.get_center() + Vector2(0, 25)
	var top = Geometry2D.segment_intersects_segment(
		r.position, Vector2(r.end.x, r.position.y), l_from, l_to
	)
	var bottom = Geometry2D.segment_intersects_segment(
		Vector2(r.position.x, r.end.y), r.end, l_from, l_to
	)
	var left = Geometry2D.segment_intersects_segment(
		r.position, Vector2(r.position.x, r.end.y), l_from, l_to
	)
	var right = Geometry2D.segment_intersects_segment(
		r.end, Vector2(r.end.x, r.position.y), l_from, l_to
	)
	var best = top
	var pos = player.global_position
	if best == null || (bottom != null && (bottom - pos).length() < (best - pos).length()):
		best = bottom
	if best == null || (left != null && (left - pos).length() < (best - pos).length()):
		best = left
	if best == null || (right != null && (right - pos).length() < (best - pos).length()):
		best = right
	return best


func _process(delta):
	# TODO the code below is framerate dependent, see
	# https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/
	#var player_billionaire_dist = player.global_position - billionaire.global_position
	# if player_billionaire_dist.length() < 800:
	boss_indicator.visible = false
	global_position = lerp(position, player.global_position, 100 * delta)
	#var zoom_level = 2 - 1.4 * clamp(player_billionaire_dist.length() / 1000, 0., 1.)
	#zoom = lerp(zoom, Vector2(zoom_level, zoom_level), 10 * delta)
	#else:
	#position = lerp(position, player.position + Vector2(0, -35), 12 * delta)
	#var zoom_level = clamp(1.0 - player.velocity.length() / 400 + .3, .3, 1.8)
	#zoom_level += 2.4
	#zoom = lerp(zoom, Vector2(zoom_level, zoom_level), 2 * delta)
	#var col_pt = collision(get_camera_rect(), billionaire.global_position)
	#if col_pt != null:
	#boss_indicator.visible = true
	#boss_indicator.global_position = col_pt
	#else:
	#boss_indicator.visible = false

	# Fade out the intensity over time
	shake_strength = lerp(shake_strength, 0., shake_decay_rate * delta)

	# Shake by adjusting camera.offset so we can move the camera around the level via it's position
	offset = get_noise_offset(delta)
