class_name UpgradeCardData
extends Resource

enum CardType {
	PROFIT,
	SPEED,
	JUMP,
	BULLET_TIME,
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
}

enum EffectType {
	# upgradeable effects
	BULLET_TIME,
	COMBO_MULTIPLIER,
	JUMP_HEIGHT,
	MOVEMENT_SPEED,
	AIR_CONTROL,
	LOOT_QUANTITY,
	LOOT_VALUE,
	BITCOIN_VALUE,
	# ability effects
	ABILITY_DASH_DOWN,
	ABILITY_DASH,
	ABILITY_DOUBLE_JUMP,
	ABILITY_AIR_ATTACK_BONUS_JUMP,
}

const ICON_PROFIT = preload("res://assets/sprites/upgrade_selector/icon_profit.png")
const ICON_SPEED = preload("res://assets/sprites/upgrade_selector/icon_speed.png")
const ICON_JUMP = preload("res://assets/sprites/upgrade_selector/icon_jump.png")
const ICON_BULLET_TIME = preload("res://assets/sprites/upgrade_selector/icon_bullet_time.png")

@export var id: String = "default_id"
@export var dependencies: Array[String] = []

@export var card_type: CardType
@export var rarity: Rarity

@export var category: String
# category_level: 0 = not upgradeable, 1 = tier 1 upgrade, 2 = tier 2 upgrade, etc.
@export var category_level: int

@export var title: String
@export var description: String
@export var cost: int

@export var icon: Texture2D

@export var effects: Dictionary[EffectType, int] = {}


# gdlint: disable=function-arguments-number
func _init(
	p_id: String = "default_id",
	p_card_type: CardType = CardType.PROFIT,
	p_rarity: Rarity = Rarity.COMMON,
	p_category: String = "default_category",
	p_category_level: int = 0,
	p_title: String = "Card Title",
	p_description: String = "",
	p_cost: int = 0,
	p_effects: Dictionary[EffectType, int] = {},
	p_dependencies: Array[String] = [],
	p_icon: Texture2D = null,
):
	id = p_id
	card_type = p_card_type
	rarity = p_rarity
	category = p_category
	category_level = p_category_level
	title = p_title
	description = p_description
	cost = p_cost
	effects = p_effects
	dependencies = p_dependencies
	icon = p_icon if p_icon != null else _get_default_icon()


func _get_default_icon() -> Texture2D:
	match card_type:
		CardType.PROFIT:
			return ICON_PROFIT
		CardType.SPEED:
			return ICON_SPEED
		CardType.JUMP:
			return ICON_JUMP
		CardType.BULLET_TIME:
			return ICON_BULLET_TIME
		_:
			return null
