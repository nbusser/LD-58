extends Node

signal scene_ended(status: EndSceneStatus, params: Dictionary)
# Status sent along with signal end_scene()
enum EndSceneStatus {
	# Main meu
	MAIN_MENU_CLICK_START,
	MAIN_MENU_CLICK_SELECT_LEVEL,
	MAIN_MENU_CLICK_CREDITS,
	MAIN_MENU_CLICK_QUIT,
	# Level
	LEVEL_END,
	LEVEL_GAME_OVER,
	LEVEL_RESTART,
	# Game over screen
	GAME_OVER_RESTART,
	GAME_OVER_QUIT,
	# Score screen
	SCORE_SCREEN_NEXT,
	SCORE_SCREEN_RETRY,
	# Select level
	SELECT_LEVEL_SELECTED,
	SELECT_LEVEL_BACK,
	# Credits
	CREDITS_BACK,
}

enum Groups { BULLET, PLAYER }

const GROUPS_DICT: Dictionary[Groups, String] = {Groups.BULLET: "Bullet", Groups.PLAYER: "Player"}

const SAMPLE_GLOBAL_VARIABLE: int = 1


func end_scene(status: EndSceneStatus, params: Dictionary = {}) -> void:
	scene_ended.emit(status, params)


func coin_flip() -> bool:
	return randi() % 2
