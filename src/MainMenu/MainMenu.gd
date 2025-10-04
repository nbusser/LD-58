class_name MainMenu

extends Control


func _on_Start_pressed() -> void:
	Globals.end_scene(Globals.EndSceneStatus.MAIN_MENU_CLICK_START)


func _on_Credits_pressed() -> void:
	Globals.end_scene(Globals.EndSceneStatus.MAIN_MENU_CLICK_CREDITS)


func _on_Quit_pressed() -> void:
	Globals.end_scene(Globals.EndSceneStatus.MAIN_MENU_CLICK_QUIT)
