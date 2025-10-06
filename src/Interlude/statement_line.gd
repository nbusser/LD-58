class_name StatementLine

extends HBoxContainer

var _description: String = ""
var _quantity: int = 0
var _value: int = 0
var _unit_value: int = 0

@onready var description_label: Label = %DescriptionLabel
@onready var quantity_label: Label = %QuantityLabel
@onready var unit_value_label: Label = %UnitValueLabel
@onready var value_label: Label = %ValueLabel


func init(description: String, quantity: int, unit_value: int) -> void:
	_description = description
	_quantity = quantity
	_unit_value = unit_value
	_value = quantity * unit_value


func _ready() -> void:
	description_label.text = _description
	quantity_label.text = str(_quantity)
	unit_value_label.text = StringFormatter.format_currency(_unit_value)
	value_label.text = StringFormatter.format_currency(_value)
