class_name SceneManager

extends Control

signal changed_to_level_music

const LEVEL_MUSIC = 0

var current_scene:
	set = set_scene
var _last_idx: int = -1

@onready var main_menu = preload("res://src/MainMenu/MainMenu.tscn")
@onready var level = preload("res://src/Level/Level.tscn")
@onready var interlude = preload("res://src/Interlude/Interlude.tscn")
@onready var credits = preload("res://src/Credits/Credits.tscn")
@onready var game_over = preload("res://src/GameOver/GameOver.tscn")

@onready var viewport: Viewport = $SubViewportContainer/SubViewport
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var music_stream_interactive: AudioStreamInteractive = music_player.stream
@onready
var music_interactive_playback: AudioStreamPlaybackInteractive = music_player.get_stream_playback()


func set_scene(new_scene: Node) -> void:
	# Free older scene
	if current_scene:
		viewport.call("remove_child", current_scene)
		current_scene.queue_free()

	current_scene = new_scene
	viewport.add_child(current_scene)


func _ready() -> void:
	randomize()
	Globals.scene_ended.connect(self._on_end_scene)
	_run_main_menu()


func play_level_music() -> void:
	music_interactive_playback.switch_to_clip(LEVEL_MUSIC)


func _process(_delta: float) -> void:
	if Input.is_action_pressed("quit"):
		get_tree().quit()

	var idx := music_interactive_playback.get_current_clip_index()
	if idx != _last_idx:
		_last_idx = idx
		if idx == LEVEL_MUSIC:
			emit_signal("changed_to_level_music")


func _reset_game_state() -> void:
	GameState.reset()


func _quit_game() -> void:
	get_tree().quit()


func _run_main_menu() -> void:
	var scene: MainMenu = main_menu.instantiate()
	# change_music_track(music_players[0])
	self.current_scene = scene


func _start_game() -> void:
	_reset_game_state()
	_run_level()


# Load current level
func _run_level() -> void:
	var scene: Level = level.instantiate()
	# Provides its settings to the level
	scene.init(GameState.current_phase, GameState.player_stats)
	# Play level music
	play_level_music()
	# TODO restore later
	# await changed_to_level_music
	self.current_scene = scene


func _run_selected_level(level_i: int) -> void:
	GameState.current_phase = level_i
	_run_level()


func _run_interlude() -> void:
	var scene: Interlude = interlude.instantiate()
	self.current_scene = scene


func _on_end_of_level(level_state: LevelState) -> void:
	# Update game state depending on level result
	GameState.latest_level_state = level_state
	GameState.player_cash = level_state.player_cash
	GameState.billionaire_cash = level_state.billionaire_net_worth

	# Load interlude
	_run_interlude()


func _on_end_of_interlude() -> void:
	_run_next_level()


func _on_game_won():
	_run_credits(false)


func _on_game_over() -> void:
	var scene: GameOver = game_over.instantiate()
	self.current_scene = scene


func _restart_level() -> void:
	_run_level()


func _run_next_level() -> void:
	GameState.current_phase += 1
	_run_level()


func _run_credits(can_go_back: bool) -> void:
	var scene: Credits = credits.instantiate()
	scene.set_back(can_go_back)
	self.current_scene = scene


# State machine handling the state of the whole game
# Everytime a scene ends, it calls this function which will load the next
# step of the game
func _on_end_scene(status: Globals.EndSceneStatus, params: Dictionary = {}) -> void:
	match status:
		Globals.EndSceneStatus.MAIN_MENU_CLICK_START:
			_start_game()
		Globals.EndSceneStatus.MAIN_MENU_CLICK_CREDITS:
			_run_credits(true)
		Globals.EndSceneStatus.MAIN_MENU_CLICK_QUIT:
			_quit_game()
		Globals.EndSceneStatus.LEVEL_END:
			var level_state: LevelState = params["level_state"]
			_on_end_of_level(level_state)
		Globals.EndSceneStatus.LEVEL_GAME_OVER:
			_on_game_over()
		Globals.EndSceneStatus.LEVEL_RESTART:
			_restart_level()
		Globals.EndSceneStatus.LEVEL_END_WIN_GAME:
			_on_game_won()
		Globals.EndSceneStatus.INTERLUDE_END:
			_on_end_of_interlude()
		Globals.EndSceneStatus.GAME_OVER_RESTART:
			_restart_level()
		Globals.EndSceneStatus.GAME_OVER_QUIT:
			_quit_game()
		Globals.EndSceneStatus.SELECT_LEVEL_BACK:
			_run_main_menu()
		Globals.EndSceneStatus.CREDITS_BACK:
			_run_main_menu()
		_:
			assert(false, "No handler for status " + str(status))
