class_name Level

extends Node

signal billionaire_hit(amount: int, remaining_net_worth: int)

var level_state: LevelState

@onready var hud: HUD = $UI/HUD
@onready var timer: Timer = $Timer
@onready var _player: Player = $Map/Player
@onready var _billionaire: Billionaire = $Map/Billionaire


func _ready():
	assert(level_state, "init must be called before creating Level scene")
	hud.init(level_state)

	if is_instance_valid(_player):
		_player.billionaire_punched.connect(_on_player_billionaire_punched)

	if is_instance_valid(_billionaire):
		billionaire_hit.connect(_billionaire.on_level_billionaire_hit)


func init(level_number_p: int, level_data_p: LevelData, nb_coins_p: int):
	level_state = LevelState.new(level_number_p, level_data_p, nb_coins_p)


func _on_Timer_timeout():
	# Simulates game state change
	level_state.nb_coins += randi() % 100

	if randi() % 4:
		Globals.end_scene(Globals.EndSceneStatus.LEVEL_GAME_OVER)
	else:
		Globals.end_scene(Globals.EndSceneStatus.LEVEL_END, {"new_nb_coins": level_state.nb_coins})


func _on_player_billionaire_punched(amount: int) -> void:
	var remaining_net_worth: int = level_state.reduce_billionaire_net_worth(amount)
	billionaire_hit.emit(amount, remaining_net_worth)
