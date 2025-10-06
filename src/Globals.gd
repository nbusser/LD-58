extends Node

signal scene_ended(status: EndSceneStatus, params: Dictionary)
signal slowmo_state_changed(active: bool)
# Status sent along with signal end_scene()
enum EndSceneStatus {
	# Main meu
	MAIN_MENU_CLICK_START,
	MAIN_MENU_CLICK_CREDITS,
	MAIN_MENU_CLICK_QUIT,
	# Level
	LEVEL_END,
	LEVEL_GAME_OVER,
	LEVEL_RESTART,
	LEVEL_END_WIN_GAME,
	# Interlude
	INTERLUDE_END,
	# Game over screen
	GAME_OVER_RESTART,
	GAME_OVER_QUIT,
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
var year = 2025


func end_scene(status: EndSceneStatus, params: Dictionary = {}) -> void:
	scene_ended.emit(status, params)


func coin_flip() -> bool:
	return randi() % 2


func create_slowmo(slowmo_name: String, factor: float) -> bool:
	if slowmo_name in slowmos:
		return false
	slowmos[slowmo_name] = factor
	Engine.time_scale *= factor
	slowmo_state_changed.emit(true)
	return true


func cancel_slowmo_if_exists(slowmo_name: String) -> void:
	if slowmo_name not in slowmos:
		return
	Engine.time_scale /= slowmos[slowmo_name]
	slowmos.erase(slowmo_name)
	if slowmos.size() == 0:
		Engine.time_scale = 1.0
	slowmo_state_changed.emit(false)
