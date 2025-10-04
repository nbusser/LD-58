@tool
extends Control

@export_tool_button("Update Display") var update_display_action = _update_display

@export var card_data: UpgradeCardData:
	set(value):
		card_data = value
		_update_display()

var _is_ready: bool = false

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
