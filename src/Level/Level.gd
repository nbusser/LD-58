class_name Level

extends Node

signal billionaire_hit(amount: int, remaining_net_worth: int)

var level_state: LevelState

@onready var hud: HUD = $UI/HUD
@onready var timer: Timer = $Timer
@onready var _player: Player = $Map/Player
@onready var _billionaire: Billionaire = $Map/Billionaire


func _fadeout(time: float = 1.5):
	await (
		get_tree()
		. create_tween()
		. tween_property($UI/Fadeout, "color:a", 1.0, time)
		. set_trans(Tween.TRANS_LINEAR)
		. set_ease(Tween.EASE_IN_OUT)
		. finished
	)


func _ready():
	assert(level_state, "init must be called before creating Level scene")
	hud.init(level_state)

	if is_instance_valid(_player):
		_player.billionaire_punched.connect(_on_player_billionaire_punched)

	if is_instance_valid(_billionaire):
		billionaire_hit.connect(_billionaire.on_level_billionaire_hit)


func init(level_number_p: int, level_data_p: LevelData):
	level_state = LevelState.new(level_number_p, level_data_p, 0, GameState.billionaire_cash, false)


func change_net_worth(damount: int):
	var remaining_net_worth: int = level_state.change_billionaire_net_worth(damount)
	hud.billionaire_net_worth = remaining_net_worth
	return remaining_net_worth


func _on_Timer_timeout():
	_player.on_level_timeout()
	_billionaire.on_level_timeout()

	await get_tree().create_timer(1.5).timeout
	await _fadeout(2.5)
	await get_tree().create_timer(0.5).timeout

	(
		Globals
		. end_scene(
			Globals.EndSceneStatus.LEVEL_END,
			{
				"level_state": level_state,
			}
		)
	)


func _on_player_billionaire_punched(amount: int) -> void:
	var remaining_net_worth: int = change_net_worth(amount)
	billionaire_hit.emit(amount, remaining_net_worth)


func on_coin_collected(collectible_type: Collectible.CollectibleType) -> void:
	level_state.collect_item(collectible_type)
	var value_of_collected_items = level_state.get_value_of_collected_items()
	level_state.player_cash = GameState.player_cash + value_of_collected_items
	hud.set_nb_coins(value_of_collected_items)


func on_player_dies(animation_finished_coroutine_to_await: Callable):
	level_state.lost = true
	_billionaire.on_player_dies()

	await animation_finished_coroutine_to_await.call()
	await _fadeout()
	await get_tree().create_timer(0.5).timeout

	Globals.end_scene(Globals.EndSceneStatus.LEVEL_GAME_OVER)
	# (
	# 	Globals
	# 	. end_scene(
	# 		Globals.EndSceneStatus.LEVEL_END,
	# 		{
	# 			"level_state": level_state,
	# 		}
	# 	)
	# )
