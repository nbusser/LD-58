class_name LevelState

extends Resource

# Represents the state of the level
# Carries the level configuration but also holds game context information

var level_number: int = 0

var player_cash: int = 0  # Coins collected from the beggining of game
var billionaire_initial_net_worth: int = 0
var billionaire_net_worth: int = 0
var lost: bool = false

var collected_items: Dictionary[Collectible.CollectibleType, int] = {}


func _init(level_number_p: int, player_cash_p: int, billionaire_cash_p: int, lost_p: bool):
	self.level_number = level_number_p
	self.player_cash = player_cash_p
	# self.billionaire_initial_net_worth = _compute_initial_billionaire_net_worth(level_number_p)
	self.billionaire_initial_net_worth = billionaire_cash_p
	self.billionaire_net_worth = self.billionaire_initial_net_worth
	self.lost = lost_p


func get_percentage_net_worth_remaining() -> float:
	return (billionaire_net_worth * 100.0) / billionaire_initial_net_worth


func change_billionaire_net_worth(damount: int) -> int:
	billionaire_net_worth = max(0, billionaire_net_worth - damount)
	return billionaire_net_worth


func _compute_initial_billionaire_net_worth(level_number_p: int) -> int:
	# Simple progression curve that scales with the level index
	return 1000 * (level_number_p + 1)


func collect_item(collectible_type: Collectible.CollectibleType) -> void:
	if collectible_type in collected_items:
		collected_items[collectible_type] += 1
	else:
		collected_items[collectible_type] = 1


func get_value_of_collected_items() -> int:
	var total_value: int = 0
	for item_type in collected_items.keys():
		var quantity: int = collected_items[item_type]
		total_value += quantity * Collectible.get_collectible_value(item_type)
	return total_value
