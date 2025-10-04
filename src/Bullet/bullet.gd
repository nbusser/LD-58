class_name Bullet

extends Area2D

var _direction: Vector2
var _speed: float

var _initialized = false
func init(start_position: Vector2, direction: Vector2, speed: float = 100) -> void:
	_initialized = true
	self.position = start_position
	_direction = direction.normalized()
	if speed > 0.0:
		_speed = speed
	rotation = _direction.angle()

func _ready() -> void:
	assert(_initialized, "init() must be called")

func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta

func _on_area_entered(_area: Area2D) -> void:
	print("HIT")
	#queue_free()
