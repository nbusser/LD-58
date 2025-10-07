class_name Victory

extends Control


func _ready() -> void:
	$AnimationPlayer.play("roll")
	$BillionaireSprite.play("death")


func _on_roll_finished() -> void:
	Globals.end_scene(Globals.EndSceneStatus.MAIN_MENU_CLICK_CREDITS)
