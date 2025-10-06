class_name UpgradeSelector

extends Control

signal close

const ICON_TEXTURE = preload("res://assets/sprites/icon.png")

const UpgradeCard = preload("res://src/UpgradeSelector/upgrade_card.gd")

@export var available_cards: Array[UpgradeCardData] = [
	UpgradeCardData.new(
		UpgradeCardData.CardType.UTILITY,
		UpgradeCardData.Rarity.COMMON,
		"speed",
		1,
		"Smooth Shoes",
		"1-year ROI",
		ICON_TEXTURE,
		{UpgradeCardData.EffectType.SPEED: 2}
	),
	UpgradeCardData.new(
		UpgradeCardData.CardType.UTILITY,
		UpgradeCardData.Rarity.UNCOMMON,
		"speed",
		2,
		"Swift Sneakers",
		"2-year ROI",
		ICON_TEXTURE,
		{UpgradeCardData.EffectType.SPEED: 3}
	),
	UpgradeCardData.new(
		UpgradeCardData.CardType.KNOWLEDGE,
		UpgradeCardData.Rarity.UNCOMMON,
		"crypto",
		1,
		"Crypto Crash Course",
		"Avoiding scams made easy",
		ICON_TEXTURE,
		{UpgradeCardData.EffectType.CRYPTO_CURRENCY: 1}
	),
	UpgradeCardData.new(
		UpgradeCardData.CardType.DEFENSE,
		UpgradeCardData.Rarity.COMMON,
		"shield",
		1,
		"Basic Firewall",
		"Blocks minor threats",
		ICON_TEXTURE,
		{UpgradeCardData.EffectType.SHIELD: 3}
	),
]

var selectable_cards: Array[UpgradeCardData] = []

var _card_pool: Array[UpgradeCardData] = available_cards.duplicate_deep()

@onready var card_container: Control = %CardContainer
@onready var _cursor: Node2D = %Cursor


func _reset_selectable_cards() -> void:
	_card_pool.append_array(selectable_cards)
	selectable_cards.clear()
	_update_cards_display()


func _pick_cards(nb_cards: int) -> Array[UpgradeCardData]:
	_reset_selectable_cards()

	var cards: Array[UpgradeCardData] = []

	var legal_card_pool: Array[UpgradeCardData] = _card_pool.filter(
		func(card: UpgradeCardData) -> bool: return GameState.is_upgrade_applicable(card)
	)

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(nb_cards):
		if legal_card_pool.size() == 0:
			break
		var index = rng.randi_range(0, legal_card_pool.size() - 1)
		_card_pool.erase(legal_card_pool[index])
		cards.append(legal_card_pool.pop_at(index))

	selectable_cards = cards
	_update_cards_display()
	return cards


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	for child in card_container.get_children():
		if child is UpgradeCard:
			child.card_selected.connect(_on_card_selected.bind(child.get_index()))
	_pick_cards(3)


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_card_selected(card_data: UpgradeCardData, index: int) -> void:
	print("Selected card index: %d" % index)
	var applied = GameState.apply_upgrade(card_data)
	if not applied:
		return
	selectable_cards.pop_at(index)
	_reset_selectable_cards()
	emit_signal("close")


func _on_redraw_button_up() -> void:
	_pick_cards(3)


func _update_cards_display() -> void:
	for i in range(3):
		var card_control = card_container.get_child(i)
		if card_control == null:
			continue
		if i < selectable_cards.size():
			card_control.card_data = selectable_cards[i]
			card_control.visible = true
		else:
			card_control.visible = false


func _process(_delta):
	_cursor.position = get_local_mouse_position()
