class_name RepulsiveWave

extends Node2D

var _is_running = false

@onready var _columns = $Columns
@onready var _player = %Player
@onready var _billionaire = %Billionaire


func _ready() -> void:
	var on_hit = func(body: Node2D) -> void:
		if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.PLAYER]):
			_player.get_hurt(Vector2(0, 0))

	for column: Area2D in _columns.get_children():
		column.visible = false
		column.monitoring = false
		column.monitorable = false
		column.connect("body_entered", on_hit)

	visible = true


func spawn(spawn_interval: float):
	if _is_running:
		return

	_is_running = true

	global_position.x = _billionaire.global_position.x

	var delayed_sound = func():
		await get_tree().create_timer(randf_range(0.5, 0.8)).timeout
		$ColumnSound.play()

	for column: Area2D in _columns.get_children():
		column.visible = true
		column.monitoring = true
		for sprite in column.get_node("Sprites").get_children():
			delayed_sound.call_deferred()
			sprite.play("default")
		await get_tree().create_timer(spawn_interval).timeout

	await get_tree().create_timer(1.0).timeout

	for column: Area2D in _columns.get_children():
		column.visible = false
		column.monitoring = false

	_is_running = false
