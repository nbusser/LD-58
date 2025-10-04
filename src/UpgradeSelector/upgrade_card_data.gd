class_name UpgradeCardData
extends Resource

enum CardType {
	ATTACK,
	DEFENSE,
	UTILITY,
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
}

enum EffectType {
	DAMAGE,
	HEAL,
	SHIELD,
}

@export var card_type: CardType
@export var rarity: Rarity

@export var category: String
# category_level: 0 = not upgradeable, 1 = tier 1 upgrade, 2 = tier 2 upgrade, etc.
@export var category_level: int

@export var title: String
@export var description_lines: PackedStringArray

@export var icon: Texture2D

@export var effects: Dictionary[EffectType, int] = {}


func _init(
	p_card_type = CardType.ATTACK,
	p_rarity = Rarity.COMMON,
	p_category = "default_category",
	p_category_level = 0,
	p_title = "Card Title",
	p_description_lines = [],
	p_icon = null,
	p_effects = {}
):
	card_type = p_card_type
	rarity = p_rarity
	category = p_category
	category_level = p_category_level
	title = p_title
	description_lines = p_description_lines
	icon = p_icon
	effects = p_effects
