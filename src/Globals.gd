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
	# Interlude
	INTERLUDE_END,
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

enum Groups { BULLET, PLAYER, BILLIONAIRE, COIN }

const GROUPS_DICT: Dictionary[Groups, String] = {
	Groups.BULLET: "Bullet",
	Groups.PLAYER: "Player",
	Groups.BILLIONAIRE: "Billionaire",
	Groups.COIN: "coin"
}

const SAMPLE_GLOBAL_VARIABLE: int = 1

var slowmos: Dictionary[String, float] = {}


func end_scene(status: EndSceneStatus, params: Dictionary = {}) -> void:
	scene_ended.emit(status, params)


func coin_flip() -> bool:
	return randi() % 2


func create_slowmo(slowmo_name: String, factor: float) -> void:
	slowmos[slowmo_name] = factor
	Engine.time_scale *= factor


func cancel_slowmo_if_exists(slowmo_name: String) -> void:
	if slowmo_name in slowmos:
		Engine.time_scale /= slowmos[slowmo_name]
		if abs(Engine.time_scale - 1.0) < 0.01:
			Engine.time_scale = 1.0
		slowmos.erase(slowmo_name)
