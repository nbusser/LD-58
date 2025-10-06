class_name StatementLine

extends HBoxContainer

var _collectible_type: Collectible.CollectibleType = Collectible.CollectibleType.DOLLAR_COIN
var _quantity: int = 0
var _value: int = 0
var _unit_value: int = 0

@onready var icon: TextureRect = %Icon
@onready var description_label: Label = %DescriptionLabel
@onready var quantity_label: Label = %QuantityLabel
@onready var unit_value_label: Label = %UnitValueLabel
@onready var value_label: Label = %ValueLabel


func init(collectible_type: Collectible.CollectibleType, quantity: int, unit_value: int) -> void:
	_collectible_type = collectible_type
	_quantity = quantity
	_unit_value = unit_value
	_value = quantity * unit_value


func _ready() -> void:
	icon.texture = Collectible.get_collectible_icon(_collectible_type)
	description_label.text = Collectible.get_collectible_name(_collectible_type)
	quantity_label.text = str(_quantity)
	unit_value_label.text = StringFormatter.format_currency(_unit_value)
	value_label.text = StringFormatter.format_currency(_value)
