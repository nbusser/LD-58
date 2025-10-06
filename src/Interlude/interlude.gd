class_name Interlude

extends Control

var statement_line_scene = preload("res://src/Interlude/statement_line.tscn")

@onready var statement_lines_container: VBoxContainer = %Recap/%StatementLinesContainer
@onready var panel = %Panel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var total_value_label: Label = %Recap/%TotalValueLabel
@onready var losses_label: Label = %LossesLabel
@onready var remaining_net_worth_label: Label = %RemainingNetWorthLabel


func _blocking_dialog(text: String):
	panel.visible = true
	subtitle_label.text = text
	while true:
		await get_tree().process_frame
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break
	panel.visible = false


func _cutscene():
	if !GameState.latest_level_state.lost:
		await _blocking_dialog("Got him good!")
	else:
		await _blocking_dialog("Je me suis fait hagar")

	$UpgradeSelector.visible = true
	await $UpgradeSelector.close

	await get_tree().create_timer(0.1).timeout


func _ready():
	_setup_statement_lines()

	panel.visible = false
	$UpgradeSelector.visible = false

	await _cutscene()

	Globals.end_scene(Globals.EndSceneStatus.INTERLUDE_END)


func _setup_statement_lines():
	for child in statement_lines_container.get_children():
		child.queue_free()

	for collectible_type in Collectible.CollectibleType.values():
		if collectible_type not in GameState.latest_level_state.collected_items:
			continue

		var value = GameState.latest_level_state.collected_items[collectible_type]

		if value <= 0:
			continue

		var statement_line: StatementLine = statement_line_scene.instantiate()
		var unit_value = Collectible.get_collectible_value(collectible_type)
		(
			statement_line
			. init(
				collectible_type,
				value,
				unit_value,
			)
		)
		statement_lines_container.add_child(statement_line)

	total_value_label.text = StringFormatter.format_currency(
		GameState.latest_level_state.get_value_of_collected_items()
	)

	losses_label.text = StringFormatter.format_currency(
		GameState.latest_level_state.get_value_of_collected_items()
	)
	var remaining_net_worth = (
		GameState.billionaire_cash - GameState.latest_level_state.get_value_of_collected_items()
	)
	remaining_net_worth_label.text = StringFormatter.format_currency(remaining_net_worth)
