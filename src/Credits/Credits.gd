class_name Credits

extends Control

var back_button_visible: bool

@onready var back_button = $Back


func _ready() -> void:
	assert(back_button_visible != null)  # ,"set_back must be called before creating Credits scene")
	if back_button_visible:
		back_button.show()
	else:
		back_button.hide()


func set_back(value: bool) -> void:
	back_button_visible = value


func _on_Back_pressed() -> void:
	Globals.end_scene(Globals.EndSceneStatus.CREDITS_BACK)
