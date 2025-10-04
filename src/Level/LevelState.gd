class_name LevelState

extends Resource

# Represents the state of the level
# Carries the level configuration but also holds game context information

var level_number: int = 0
var level_data: LevelData  # Config of the level

var nb_coins: int = 0  # Coins collected from the beggining of game
var billionaire_initial_net_worth: int = 0
var billionaire_net_worth: int = 0


func _init(level_number_p: int, level_data_p: LevelData, nb_coins_p: int):
	self.level_number = level_number_p
	self.level_data = level_data_p
	self.nb_coins = nb_coins_p
	self.billionaire_initial_net_worth = _compute_initial_billionaire_net_worth(level_number_p)
	self.billionaire_net_worth = self.billionaire_initial_net_worth


func change_billionaire_net_worth(damount: int) -> int:
	billionaire_net_worth = max(0, billionaire_net_worth - damount)
	return billionaire_net_worth


func _compute_initial_billionaire_net_worth(level_number_p: int) -> int:
	# Simple progression curve that scales with the level index
	return 1000 * (level_number_p + 1)
