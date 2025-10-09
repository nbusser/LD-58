class_name MainMenu

extends Control

@onready var _cursor: Cursor = %Cursor


func _on_start_game_card_card_selected(signature: Signature) -> void:
	await _cursor.sign(signature)
	Globals.end_scene(Globals.EndSceneStatus.MAIN_MENU_CLICK_START)


func _on_credits_card_card_selected(signature: Signature) -> void:
	await _cursor.sign(signature)
	Globals.end_scene(Globals.EndSceneStatus.MAIN_MENU_CLICK_CREDITS)
