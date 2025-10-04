class_name Level

extends Node

var level_state: LevelState

@onready var hud: HUD = $UI/HUD
@onready var timer: Timer = $Timer


func _ready():
	assert(level_state, "init must be called before creating Level scene")
	hud.init(level_state)


func init(level_number_p: int, level_data_p: LevelData, nb_coins_p: int):
	level_state = LevelState.new(level_number_p, level_data_p, nb_coins_p)


func _on_Timer_timeout():
	# Simulates game state change
	level_state.nb_coins += randi() % 100

	if randi() % 4:
		Globals.end_scene(Globals.EndSceneStatus.LEVEL_GAME_OVER)
	else:
		Globals.end_scene(Globals.EndSceneStatus.LEVEL_END, {"new_nb_coins": level_state.nb_coins})
