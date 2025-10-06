class_name AttackPattern

extends Node2D

@export var attack_name: String
@export var net_worth_percent_threshold: float = 100.0
@export var cooldown: float = 0.0
@export var minimum_difficulty_factor: float = 1.0

# Normalized distance to the player
# 0.0 means the player is next to boss
# 1.0 means the player and the boss are in each walls
@export var minimum_distance_x: float = 0.0
@export var maximum_distance_x: float = 1.0
@export var prefered_distance_x: float = 0.3
@export var prefered_distance_tolerance_x: float = 0.1

# Can be lowered if the attack is more rare
@export var base_weigth: float = 1.0

@export var enabled: bool = true

var routine: Callable

@onready var _cooldown_timer: Timer = $Cooldown


func is_ready() -> bool:
	return _cooldown_timer.is_stopped()


func call_routine() -> void:
	assert(routine.is_valid(), "routine must be set manually by the parent")
	if cooldown > 0.0:
		_cooldown_timer.start(cooldown)
	await routine.call()


func calculate_weight(
	theoretical_max_distance_x: float, distance_to_player_x: float, billionaire_money: float
) -> float:
	# We know the theoretical maximum distance (arena width), so we can normalize distance to player
	var normalized_distance = clamp(distance_to_player_x / theoretical_max_distance_x, 0.0, 1.0)
	if (
		not enabled
		or not is_ready()
		or billionaire_money > net_worth_percent_threshold
		or normalized_distance < minimum_distance_x
		or normalized_distance > maximum_distance_x
		or GameState._get_difficulty_factor() < minimum_difficulty_factor
	):
		return 0.0

	# Pompé à un LLM. A surveiller

	# Gaussian proximity factor
	var diff = normalized_distance - prefered_distance_x
	var distance_factor = exp(-pow(diff, 2) / (2.0 * pow(prefered_distance_tolerance_x, 2)))

	return base_weigth * distance_factor
