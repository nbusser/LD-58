class_name UpgradeCardData
extends Resource

enum CardType {
	ATTACK,
	DEFENSE,
	UTILITY,
	KNOWLEDGE,
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
	SPEED,
	CRYPTO_CURRENCY,
}

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


func _init(
	p_id: String = "default_id",
	p_dependencies: Array[String] = [],
	p_card_type: CardType = CardType.ATTACK,
	p_rarity: Rarity = Rarity.COMMON,
	p_category: String = "default_category",
	p_category_level: int = 0,
	p_title: String = "Card Title",
	p_description: String = "",
	p_cost: int = 0,
	p_icon: Texture2D = null,
	p_effects: Dictionary[EffectType, int] = {}
):
	id = p_id
	dependencies = p_dependencies
	card_type = p_card_type
	rarity = p_rarity
	category = p_category
	category_level = p_category_level
	title = p_title
	description = p_description
	cost = p_cost
	icon = p_icon
	effects = p_effects
