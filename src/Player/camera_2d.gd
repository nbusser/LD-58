extends Camera2D

@onready var player = $"../Player"


func _process(_delta):
	position = player.position
	var zoom_level = clamp(1.0 - player.velocity.length() / 2000 + .3, .3, 1.3)
	zoom = lerp(zoom, Vector2(zoom_level, zoom_level), 2 * _delta)
