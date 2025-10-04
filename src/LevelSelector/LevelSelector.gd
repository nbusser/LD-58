class_name LevelSelector

extends Control

var levels: Array[LevelData]

@onready var level_list = $PanelContainer/HBoxContainer/VBoxContainer/LevelList
@onready var level_btn = preload("res://src/LevelSelector/LevelButton.tscn")


func _ready() -> void:
	for i in range(levels.size()):
		var level_btn_instance: LevelButton = level_btn.instantiate()
		level_btn_instance.init(levels[i], i)
		level_btn_instance.level_clicked.connect(self._selected)
		level_list.add_child(level_btn_instance)


func init(data: Array[LevelData]) -> void:
	self.levels = data


func _selected(level_index: int) -> void:
	Globals.end_scene(Globals.EndSceneStatus.SELECT_LEVEL_SELECTED, {"level_i": level_index})


func _on_back_pressed() -> void:
	Globals.end_scene(Globals.EndSceneStatus.SELECT_LEVEL_BACK)
