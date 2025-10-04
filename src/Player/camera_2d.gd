extends Camera2D

@onready var player = $"../Player"


func _process(_delta):
	# TODO the code below is framerate dependent, see
	# https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/
	position = lerp(position, player.position, 10*_delta)
	var zoom_level = clamp(1.0 - player.velocity.length() / 2000 + .3, .3, 1.3)
	zoom = lerp(zoom, Vector2(zoom_level, zoom_level), 2 * _delta)
