class_name BubbleBarrier

extends Node2D

var _is_running = false

@onready var _waves = $Waves
@onready var _billionaire = %Billionaire


func spawn(spawn_interval: float):
	if _is_running:
		return

	_is_running = true

	global_position.x = _billionaire.global_position.x

	for wave: Node2D in _waves.get_children():
		for bubble: Bubble in wave.get_children():
			bubble.spawn(false)
		await get_tree().create_timer(spawn_interval).timeout

	await get_tree().create_timer(1.0).timeout

	_is_running = false
