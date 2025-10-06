extends Node

enum CollectibleType { DOLLAR_COIN, DOLLAR_BILL, BUNDLE_OF_CASH, MONEY_BAG, GOLD_BAR, BITCOIN }


func get_collectible_value(collectible_type: CollectibleType) -> int:
	match collectible_type:
		CollectibleType.DOLLAR_COIN:
			return 1
		CollectibleType.DOLLAR_BILL:
			return 20
		CollectibleType.BUNDLE_OF_CASH:
			return 100
		CollectibleType.MONEY_BAG:
			return 1000
		CollectibleType.GOLD_BAR:
			return 10000
		CollectibleType.BITCOIN:
			return 100000
		_:
			return 0


func get_collectible_name(collectible_type: CollectibleType) -> String:
	match collectible_type:
		CollectibleType.DOLLAR_COIN:
			return "Dollar Coin"
		CollectibleType.DOLLAR_BILL:
			return "Dollar Bill"
		CollectibleType.BUNDLE_OF_CASH:
			return "Bundle of Cash"
		CollectibleType.MONEY_BAG:
			return "Money Bag"
		CollectibleType.GOLD_BAR:
			return "Gold Bar"
		CollectibleType.BITCOIN:
			return "Bitcoin"
		_:
			return "Unknown"


func get_collectible_icon(collectible_type: CollectibleType) -> Texture2D:
	match collectible_type:
		CollectibleType.DOLLAR_COIN:
			return preload("res://assets/sprites/collectibles/dollar_coin.png")
		CollectibleType.DOLLAR_BILL:
			return preload("res://assets/sprites/collectibles/dollar_bill.png")
		CollectibleType.BUNDLE_OF_CASH:
			return preload("res://assets/sprites/collectibles/dollar_wad.png")
		CollectibleType.MONEY_BAG:
			return preload("res://assets/sprites/collectibles/money_bag.png")
		CollectibleType.GOLD_BAR:
			return preload("res://assets/sprites/collectibles/gold_bar_icon.png")
		CollectibleType.BITCOIN:
			return preload("res://assets/sprites/collectibles/bitcoin_coin.png")
		_:
			return preload("res://assets/sprites/icon.png")
