class_name Interlude

extends Control


func _blocking_dialog(text: String):
	$Panel.visible = true
	$Panel/VBoxContainer/Label.text = text
	while true:
		await get_tree().process_frame
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break
	$Panel.visible = false


func _cutscene():
	await (
		get_tree()
		. create_tween()
		. tween_property($Player, "position:x", 540.0, 1.0)
		. set_trans(Tween.TRANS_LINEAR)
		. set_ease(Tween.EASE_IN_OUT)
		. finished
	)

	await get_tree().create_timer(0.1).timeout
	await _blocking_dialog("Je l'ai bien schlassé")

	$UpgradeSelector.visible = true
	await $UpgradeSelector.close

	await get_tree().create_timer(0.1).timeout
	await _blocking_dialog("Tro kool")

	await (
		get_tree()
		. create_tween()
		. tween_property($Player, "position:x", -68.0, 1.0)
		. set_trans(Tween.TRANS_LINEAR)
		. set_ease(Tween.EASE_IN_OUT)
		. finished
	)


func _ready():
	$Player.position = Vector2(-68.0, 417.0)
	$Panel.visible = false
	$UpgradeSelector.visible = false

	$UpgradeSelector.init(GameState.player_cash)

	await _cutscene()

	Globals.end_scene(Globals.EndSceneStatus.INTERLUDE_END)
