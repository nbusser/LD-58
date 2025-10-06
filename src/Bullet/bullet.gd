class_name Bullet

extends Area2D

var _direction: Vector2
var _speed: float
var _knockback_force: float
var _collectible_type: Collectible.CollectibleType

var _initialized = false

var _coin_scene = preload("res://src/Coin/Coin.tscn")

@onready var _sprite_container = %SpriteContainer
@onready var _coins = $"../../Coins"


func init(
	start_position: Vector2,
	direction: Vector2,
	knockback_force: float,
	speed: float = 100,
	bullet_scale_factor: float = 1.0,
	collectible_type: Collectible.CollectibleType = Collectible.CollectibleType.DOLLAR_COIN
) -> void:
	_initialized = true
	position = start_position
	_direction = direction.normalized()
	_speed = speed
	scale *= bullet_scale_factor
	_knockback_force = knockback_force
	_collectible_type = collectible_type


func _ready() -> void:
	assert(_initialized, "init() must be called")
	_sprite_container.rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	position += _direction * _speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.PLAYER]):
		(body as Player).get_hurt(_knockback_force * _direction.normalized())
	else:
		var cs = _coin_scene.instantiate()
		cs.init(self.global_position, _collectible_type)
		_coins.call_deferred("add_child", cs)
	queue_free()
