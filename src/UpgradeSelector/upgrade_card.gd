@tool
extends Control

signal card_selected(card_data: UpgradeCardData)

const PIN_BLUE = preload("res://assets/sprites/upgrade_selector/upgrade-pin-blue.png")
const PIN_GREEN = preload("res://assets/sprites/upgrade_selector/upgrade-pin-green.png")
const PIN_ORANGE = preload("res://assets/sprites/upgrade_selector/upgrade-pin-orange.png")
const PIN_PURPLE = preload("res://assets/sprites/upgrade_selector/upgrade-pin-purple.png")
const PIN_RED = preload("res://assets/sprites/upgrade_selector/upgrade-pin-red.png")
const PIN_YELLOW = preload("res://assets/sprites/upgrade_selector/upgrade-pin-yeller.png")
const PIN_GRAY = preload("res://assets/sprites/upgrade_selector/upgrade-pin-grey.png")
const PIN_TURQUOISE = preload("res://assets/sprites/upgrade_selector/upgrade-pin-turquoise.png")

@export_tool_button("Update Display") var update_display_action = _update_display

@export var card_data: UpgradeCardData:
	set(value):
		card_data = value
		_update_display()

var _is_ready: bool = false

@onready var pin_texture_rect: TextureRect = %PinTextureRect

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var icon_texture_rect: TextureRect = %IconTextureRect
@onready var effects_label: Label = %EffectsLabel
@onready var rarity_label: Label = %RarityLabel
@onready var level_label: Label = %LevelLabel
@onready var type_label: Label = %TypeLabel


func _ready():
	_update_display()
	_is_ready = true

	pin_texture_rect.texture = (
		[
			PIN_GRAY,
			PIN_GREEN,
			PIN_BLUE,
			PIN_PURPLE,
			PIN_ORANGE,
			PIN_RED,
			PIN_YELLOW,
			PIN_TURQUOISE,
		]
		. pick_random()
	)


func _update_display() -> void:
	if card_data == null or not _is_ready:
		return
	title_label.text = card_data.title
	description_label.text = card_data.description
	icon_texture_rect.texture = card_data.icon
	effects_label.text = _format_effects(card_data.effects)
	rarity_label.text = UpgradeCardData.Rarity.keys()[card_data.rarity].capitalize()
	level_label.text = str(card_data.category_level)
	type_label.text = UpgradeCardData.CardType.keys()[card_data.card_type].capitalize()


func _format_effects(effects: Dictionary) -> String:
	var effects_str: Array[String] = []
	for effect_type in effects.keys():
		var value = effects[effect_type]
		var effect_name = UpgradeCardData.EffectType.keys()[effect_type].to_lower().replace(
			"_", " "
		)
		effects_str.append("%+d %s" % [value, effect_name])
	return ", ".join(effects_str)


func _on_select_button_button_up() -> void:
	emit_signal("card_selected", card_data)
