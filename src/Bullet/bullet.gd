class_name Bullet

extends Area2D

var _direction: Vector2
var _speed: float

var _initialized = false

@onready var _sprite = $Sprite2D


func init(start_position: Vector2, direction: Vector2, speed: float = 100) -> void:
	_initialized = true
	position = start_position
	_direction = direction.normalized()
	_speed = speed


func _ready() -> void:
	assert(_initialized, "init() must be called")
	_sprite.rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	position += _direction * _speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.PLAYER]):
		(body as Player).get_hurt()
	if !body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.BILLIONAIRE]):
		queue_free()
