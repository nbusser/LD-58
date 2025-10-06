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
	for upgr in get_upgrade_stats():
		var upgr_value = get_upgrade_stats()[upgr]
		match upgr:
			UpgradeCardData.EffectType.BULLET_TIME:
				player_stats.unlocked_bullet_proximity_slowmo = true
				player_stats.bullet_proximity_radius = 70 + upgr_value * 12
				player_stats.bullet_proximity_slow_factor = .75 - upgr_value * 0.1
			UpgradeCardData.EffectType.COMBO_MULTIPLIER:
				player_stats.combo_base = 1.5 + upgr_value * .5
			UpgradeCardData.EffectType.JUMP_HEIGHT:
				player_stats.jump_force = 6000 + upgr_value * 500
			UpgradeCardData.EffectType.MOVEMENT_SPEED:
				player_stats.ground_speed = 300 + upgr_value * 75
			UpgradeCardData.EffectType.AIR_CONTROL:
				player_stats.air_speed = 150 + upgr_value * 140
			UpgradeCardData.EffectType.LOOT_QUANTITY:
				print("TODO")
			UpgradeCardData.EffectType.LOOT_VALUE:
				print("TODO")
			UpgradeCardData.EffectType.BITCOIN_VALUE:
				print("TODO")
			UpgradeCardData.EffectType.ABILITY_DASH_DOWN:
				player_stats.unlocked_dash_down = true
				player_stats.unlocked_dash_glide = true
			UpgradeCardData.EffectType.ABILITY_DASH:
				player_stats.unlocked_dash = true
				player_stats.unlocked_dash_bullet_time = true
			UpgradeCardData.EffectType.ABILITY_DOUBLE_JUMP:
				player_stats.max_nb_jumps = 2
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
