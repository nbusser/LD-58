extends Node

const BILLIONAIRE_INITIAL_CASH = 100000000000

var current_phase: int = 0
var billionaire_cash: int = BILLIONAIRE_INITIAL_CASH
var player_cash: int = 0
var latest_level_state: LevelState = null
var active_upgrades: Array[UpgradeCardData] = []
var player_stats: PlayerStats = PlayerStats.new()

# Actualized after each phase
var difficulty_factor:
	get = _get_difficulty_factor


func _get_difficulty_factor() -> float:
	var current_phase_difficulty = current_phase * 0.5

	# The difficulty starts scaling at 10k$ loss
	var initial_offset = 4
	var lost_health = BILLIONAIRE_INITIAL_CASH - billionaire_cash
	var health_difference_difficulty = (
		max((log(lost_health) / log(10)) - initial_offset, 0.0) if lost_health != 0 else 0.0
	)

	return clamp(current_phase_difficulty + health_difference_difficulty, 1.0, 10.0)


func reset():
	current_phase = 0
	billionaire_cash = BILLIONAIRE_INITIAL_CASH
	player_cash = 0


func is_upgrade_applicable(card: UpgradeCardData) -> bool:
	if card == null:
		return false

	for dependency in card.dependencies:
		var dependency_met = false
		for existing_card in active_upgrades:
			if existing_card.id == dependency:
				dependency_met = true
				break
		if not dependency_met:
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
