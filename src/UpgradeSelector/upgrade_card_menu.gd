@tool
extends Control

signal card_selected(card_data: UpgradeCardData)
signal signature_point_added(point: Vector2)

const PIN_BLUE = preload("res://assets/sprites/upgrade_selector/upgrade-pin-blue.png")
const PIN_GREEN = preload("res://assets/sprites/upgrade_selector/upgrade-pin-green.png")
const PIN_ORANGE = preload("res://assets/sprites/upgrade_selector/upgrade-pin-orange.png")
const PIN_PURPLE = preload("res://assets/sprites/upgrade_selector/upgrade-pin-purple.png")
const PIN_RED = preload("res://assets/sprites/upgrade_selector/upgrade-pin-red.png")
const PIN_YELLOW = preload("res://assets/sprites/upgrade_selector/upgrade-pin-yeller.png")
const PIN_GRAY = preload("res://assets/sprites/upgrade_selector/upgrade-pin-grey.png")
const PIN_TURQUOISE = preload("res://assets/sprites/upgrade_selector/upgrade-pin-turquoise.png")

@export var card_data: UpgradeCardData:
	set(value):
		card_data = value
		if signature_line_2d != null:
			signature_line_2d.visible = false
var _is_ready: bool = false

@onready var pin_texture_rect: TextureRect = %PinTextureRect

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var icon_texture_rect: TextureRect = %IconTextureRect
@onready var effects_label: Label = %EffectsLabel
@onready var rarity_label: Label = %RarityLabel
@onready var level_label: Label = %LevelLabel
@onready var type_label: Label = %TypeLabel
@onready var cost_label: Label = %CostLabel
@onready var signature_line_2d: Line2D = $SignatureLine2D
@onready var select_button: Button = %SelectButton


func _ready():
	signature_line_2d.visible = false
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


func _format_effects(effects: Dictionary) -> String:
	var effects_str: Array[String] = []
	for effect_type in effects.keys():
		var value = effects[effect_type]
		var effect_name = UpgradeCardData.EffectType.keys()[effect_type].to_lower().replace(
			"_", " "
		)
		effects_str.append("%+d %s" % [value, effect_name])
	return ", ".join(effects_str)


func _on_select_button_button_down() -> void:
	print("Selected card: %s" % card_data.title)
	emit_signal("card_selected", card_data)


func sign_contract():
	var points = signature_line_2d.points.duplicate()
	signature_line_2d.points = []
	signature_line_2d.visible = true

	emit_signal("signature_point_added", signature_line_2d.position + points[0])

	for i in range(points.size()):
		var point = points[i]
		await get_tree().create_timer(0.05).timeout
		signature_line_2d.points = points.slice(0, i + 1)
		emit_signal("signature_point_added", signature_line_2d.position + point)
