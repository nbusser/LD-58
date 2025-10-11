@tool
class_name BubbleBarrier

extends Node2D

@export_tool_button("Refresh Bubble Preview") var refresh_bubble_previews = _refresh_bubble_previews

var _is_running = false

@onready var _waves = $Waves
@onready var _billionaire = %Billionaire
@onready var _coins_manager = %CoinsManager


func spawn(spawn_interval: float):
	if _is_running:
		return

	_is_running = true

	global_position.x = _billionaire.global_position.x

	for wave: Node2D in _waves.get_children():
		for bubble: Bubble in wave.get_children():
			bubble.spawn(_coins_manager, false)
		await get_tree().create_timer(spawn_interval).timeout

	await get_tree().create_timer(1.0).timeout

	_is_running = false


func _refresh_bubble_previews() -> void:
	for wave: Node2D in _waves.get_children():
		for bubble: Bubble in wave.get_children():
			bubble.update_preview_size_action.call()
