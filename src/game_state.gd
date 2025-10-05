extends Node

var current_level_number: int = 0
var billionaire_cash: int = 100000000000
var player_cash: int = 0
var latest_level_state: LevelState = null
var active_upgrades: Array[UpgradeCardData] = []


func reset():
	current_level_number = 0
	billionaire_cash = 100000000000
	player_cash = 0


func is_upgrade_applicable(card: UpgradeCardData) -> bool:
	if card == null:
		return false

	var category_exists = false
	for existing_card in active_upgrades:
		if existing_card.category == card.category:
			category_exists = true
			if card.category_level <= existing_card.category_level:
				return false

	if not category_exists and card.category_level > 1:
		return false

	return true


func apply_upgrade(card: UpgradeCardData) -> bool:
	if not is_upgrade_applicable(card):
		print("Upgrade not applicable: %s" % card.title)
		return false

	active_upgrades.append(card)
	print("Applied upgrade: %s" % card.title)
	print("Current stats: %s" % str(get_upgrade_stats()))
	return true


func get_upgrade_stats() -> Dictionary[UpgradeCardData.EffectType, int]:
	return active_upgrades.reduce(
		func(accum: Dictionary, card: UpgradeCardData):
			for type in card.effects:
				if type in accum:
					accum[type] += card.effects[type]
				else:
					accum[type] = card.effects[type]
			return accum,
		{} as Dictionary[UpgradeCardData.EffectType, int]
	)
