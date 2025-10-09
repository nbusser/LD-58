class_name Signature

extends Line2D

signal signature_point_added(point: Vector2)


func _ready():
	visible = false


func sign(speed_factor: float = 1.0):
	var points_to_draw = points.duplicate()
	points = []
	visible = true

	emit_signal("signature_point_added", global_position + points_to_draw[0])

	for i in range(points_to_draw.size()):
		var point = points_to_draw[i]
		await get_tree().create_timer(0.05 / speed_factor).timeout
		points = points_to_draw.slice(0, i + 1)
		emit_signal("signature_point_added", global_position + point)
