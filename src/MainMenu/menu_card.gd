extends Control

signal card_selected(signature: Signature)

@onready var _signature = %Signature


func _on_select_button_pressed() -> void:
	emit_signal("card_selected", _signature)
