extends Node

enum CollectibleType {
	DOLLAR_COIN, DOLLAR_BILL, BUNDLE_OF_CASH, MONEY_BAG, GOLD_BAR, BITCOIN, CRYPTO_WALLET
}


func get_collectible_value(collectible_type: CollectibleType) -> int:
	match collectible_type:
		CollectibleType.DOLLAR_COIN:
			return 1
		CollectibleType.DOLLAR_BILL:
			return 5
		CollectibleType.BUNDLE_OF_CASH:
			return 20
		CollectibleType.MONEY_BAG:
			return 100
		CollectibleType.GOLD_BAR:
			return 50
		CollectibleType.BITCOIN:
			return 500
		CollectibleType.CRYPTO_WALLET:
			return 1000
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
		CollectibleType.CRYPTO_WALLET:
			return "Crypto Wallet"
		_:
			return "Unknown"


func get_collectible_texture(collectible_type: CollectibleType) -> Texture2D:
	match collectible_type:
		CollectibleType.DOLLAR_COIN:
			return preload("res://assets/sprites/collectibles/dollar_coin.png")
		CollectibleType.DOLLAR_BILL:
			return preload("res://assets/sprites/collectibles/dollar_bill.png")
		_:
			return preload("res://assets/sprites/icon.png")
