class_name MainMenu

extends Control

@onready var _cursor: Cursor = %Cursor


func _select_menu_option(signature: Signature, end_scene: Globals.EndSceneStatus):
	# Already signing in another routine. Canceling to speed up the animation.
	if _cursor.is_signing():
		_cursor.cancel_signing()
		return

	await _cursor.sign(signature)
	Globals.end_scene(end_scene)


func _on_start_game_card_card_selected(signature: Signature) -> void:
	_select_menu_option(signature, Globals.EndSceneStatus.MAIN_MENU_CLICK_START)


func _on_credits_card_card_selected(signature: Signature) -> void:
	_select_menu_option(signature, Globals.EndSceneStatus.MAIN_MENU_CLICK_CREDITS)
