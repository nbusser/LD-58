class_name CoinsManager

extends Node2D

@onready var _level: Level = $"../../"
@onready var _coin_scene: PackedScene = preload("res://src/Coin/Coin.tscn")


func add_coin(coin: Coin) -> void:
	add_child.call_deferred(coin)


func create_coin(spawn_position: Vector2, collectible_type: Collectible.CollectibleType) -> Coin:
	# Reduce billionaire's net worth by the value of spawned collectible.
	var collectible_value = Collectible.get_collectible_value(collectible_type)
	if collectible_value > 0:
		_level.change_net_worth(collectible_value)

	var coin = _coin_scene.instantiate()
	coin.init(spawn_position, collectible_type)
	return coin


func spawn_coin(spawn_position: Vector2, collectible_type: Collectible.CollectibleType) -> Coin:
	var coin = create_coin(spawn_position, collectible_type)
	add_coin(coin)
	return coin
