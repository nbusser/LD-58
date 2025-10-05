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

# Used to keep track of where we are in the noise
# so that we can smoothly move through it
var noise_i: float = 0.0

var shake_strength: float = 0.0

@onready var player = $"../Player"
@onready var rand = RandomNumberGenerator.new()
@onready var noise = FastNoiseLite.new()


func _ready() -> void:
	rand.randomize()
	# Randomize the generated noise
	noise.seed = rand.randi()
	# Period affects how quickly the noise changes values
	noise.frequency = 0.2
	apply_noise_shake()


func apply_noise_shake() -> void:
	shake_strength = noise_shake_strength


func get_noise_offset(delta: float) -> Vector2:
	noise_i += delta * noise_shake_speed
	# Set the x values of each call to 'get_noise_2d' to a different value
	# so that our x and y vectors will be reading from unrelated areas of noise
	return Vector2(
		noise.get_noise_2d(1, noise_i) * shake_strength,
		noise.get_noise_2d(100, noise_i) * shake_strength
	)


func _process(delta):
	# TODO the code below is framerate dependent, see
	# https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/
	position = lerp(position, player.position + Vector2(0, -35), 6 * delta)
	var zoom_level = clamp(1.0 - player.velocity.length() / 400 + .3, .3, 1.8)
	zoom_level += 2.4
	zoom = lerp(zoom, Vector2(zoom_level, zoom_level), 2 * delta)

	# Fade out the intensity over time
	shake_strength = lerp(shake_strength, 0., shake_decay_rate * delta)

	# Shake by adjusting camera.offset so we can move the camera around the level via it's position
	offset = get_noise_offset(delta)
