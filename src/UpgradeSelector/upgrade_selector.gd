class_name UpgradeSelector

extends Control

signal close

const ICON_TEXTURE = preload("res://assets/sprites/icon.png")

const UpgradeCard = preload("res://src/UpgradeSelector/upgrade_card.gd")
const UpgradeCardMenu = preload("res://src/UpgradeSelector/upgrade_card_menu.gd")

@export var available_cards: Array[UpgradeCardData] = [
	# PROFIT
	UpgradeCardData.new(
		"loot_quantity_1",
		UpgradeCardData.CardType.PROFIT,
		UpgradeCardData.Rarity.COMMON,
		"loot_quantity",
		1,
		"Part-Time Thief",
		"Get your hands in unattended pockets",
		0,
		{UpgradeCardData.EffectType.LOOT_QUANTITY: 1}
	),
	UpgradeCardData.new(
		"loot_quantity_2",
		UpgradeCardData.CardType.PROFIT,
		UpgradeCardData.Rarity.UNCOMMON,
		"loot_quantity",
		2,
		"Full-Time Thief",
		"Sleight of hand is your middle name",
		2500,
		{UpgradeCardData.EffectType.LOOT_QUANTITY: 2},
		["loot_quantity_1"]
	),
	UpgradeCardData.new(
		"loot_value_1",
		UpgradeCardData.CardType.PROFIT,
		UpgradeCardData.Rarity.COMMON,
		"loot_value",
		1,
		"Appraiser",
		"Yield more profit from each heist",
		0,
		{UpgradeCardData.EffectType.LOOT_VALUE: 1}
	),
	UpgradeCardData.new(
		"loot_value_2",
		UpgradeCardData.CardType.PROFIT,
		UpgradeCardData.Rarity.UNCOMMON,
		"loot_value",
		2,
		"Golden Touch",
		"Midas would be jealous",
		2500,
		{UpgradeCardData.EffectType.LOOT_VALUE: 2},
		["loot_value_1"]
	),
	UpgradeCardData.new(
		"bitcoin_value_1",
		UpgradeCardData.CardType.PROFIT,
		UpgradeCardData.Rarity.UNCOMMON,
		"bitcoin_value",
		1,
		"Crypto Crash Course",
		"Avoiding scams made easy",
		3500,
		{UpgradeCardData.EffectType.BITCOIN_VALUE: 1},
		["loot_value_2", "loot_quantity_1"]
	),
	UpgradeCardData.new(
		"bitcoin_value_2",
		UpgradeCardData.CardType.PROFIT,
		UpgradeCardData.Rarity.RARE,
		"bitcoin_value",
		2,
		"Smart Contract Editor",
		"Write your own rules for profit",
		7500,
		{UpgradeCardData.EffectType.BITCOIN_VALUE: 2},
		["bitcoin_value_1"]
	),
	UpgradeCardData.new(
		"combo_multiplier_1",
		UpgradeCardData.CardType.PROFIT,
		UpgradeCardData.Rarity.UNCOMMON,
		"combo_multiplier",
		1,
		"Momentum Mastery",
		"Build up your streaks to maximize profit",
		4000,
		{UpgradeCardData.EffectType.COMBO_MULTIPLIER: 1},
		["loot_value_1", "loot_quantity_2"]
	),
	(
		UpgradeCardData
		. new(
			"combo_multiplier_2",
			UpgradeCardData.CardType.PROFIT,
			UpgradeCardData.Rarity.RARE,
			"combo_multiplier",
			2,
			"Streak Savant",
			"Your ability to maintain focus and precision during high-pressure situations is unparalleled",
			8000,
			{UpgradeCardData.EffectType.COMBO_MULTIPLIER: 1},
			["combo_multiplier_1"]
		)
	),
	# SPEED
	UpgradeCardData.new(
		"speed_1",
		UpgradeCardData.CardType.SPEED,
		UpgradeCardData.Rarity.COMMON,
		"speed",
		1,
		"Invest in a shoe company",
		"Get your kicks on the ground faster",
		0,
		{UpgradeCardData.EffectType.MOVEMENT_SPEED: 2, UpgradeCardData.EffectType.AIR_CONTROL: 1}
	),
	UpgradeCardData.new(
		"dash",
		UpgradeCardData.CardType.SPEED,
		UpgradeCardData.Rarity.COMMON,
		"dash",
		0,
		"Sprint to Success",
		"Quick bursts of speed to close the deal",
		1500,
		{UpgradeCardData.EffectType.ABILITY_DASH: 1}
	),
	UpgradeCardData.new(
		"speed_2",
		UpgradeCardData.CardType.SPEED,
		UpgradeCardData.Rarity.UNCOMMON,
		"speed",
		2,
		"Speedy Investor",
		"Time is money, so move like it",
		3000,
		{UpgradeCardData.EffectType.MOVEMENT_SPEED: 3, UpgradeCardData.EffectType.AIR_CONTROL: 2},
		["speed_1", "dash"]
	),
	# JUMP
	UpgradeCardData.new(
		"jump_height_1",
		UpgradeCardData.CardType.JUMP,
		UpgradeCardData.Rarity.COMMON,
		"jump_height",
		1,
		"Pogo Stick",
		"Bounce to new heights",
		0,
		{UpgradeCardData.EffectType.JUMP_HEIGHT: 2, UpgradeCardData.EffectType.AIR_CONTROL: 1}
	),
	UpgradeCardData.new(
		"double_jump",
		UpgradeCardData.CardType.JUMP,
		UpgradeCardData.Rarity.COMMON,
		"double_jump",
		0,
		"Pump and Dump",
		"Leap again to avoid falling stocks",
		2000,
		{UpgradeCardData.EffectType.ABILITY_DOUBLE_JUMP: 1},
		["jump_height_1"]
	),
	UpgradeCardData.new(
		"jump_height_2",
		UpgradeCardData.CardType.JUMP,
		UpgradeCardData.Rarity.UNCOMMON,
		"jump_height",
		2,
		"Moonshot",
		"Reach for the stars",
		3000,
		{UpgradeCardData.EffectType.JUMP_HEIGHT: 3, UpgradeCardData.EffectType.AIR_CONTROL: 2},
		["jump_height_1"]
	),
	UpgradeCardData.new(
		"dash_down",
		UpgradeCardData.CardType.JUMP,
		UpgradeCardData.Rarity.COMMON,
		"dash_down",
		0,
		"Market Crash Dive",
		"Plunge towards profit... or the ground",
		2500,
		{UpgradeCardData.EffectType.ABILITY_DASH_DOWN: 1},
		["double_jump"]
	),
	# BULLET TIME
	UpgradeCardData.new(
		"bullet_time_1",
		UpgradeCardData.CardType.BULLET_TIME,
		UpgradeCardData.Rarity.COMMON,
		"bullet_time",
		1,
		"Insider Knowledge",
		"You read the flow of money like it's moving in slow motion, always one step ahead",
		500,
		{UpgradeCardData.EffectType.BULLET_TIME: 1, UpgradeCardData.EffectType.COMBO_MULTIPLIER: 1}
	),
	(
		UpgradeCardData
		. new(
			"bullet_time_2",
			UpgradeCardData.CardType.BULLET_TIME,
			UpgradeCardData.Rarity.UNCOMMON,
			"bullet_time",
			2,
			"Market Guru",
			"Your intuition for market trends is uncanny, allowing you to capitalize on opportunities before they arise",
			5000,
			{
				UpgradeCardData.EffectType.BULLET_TIME: 1,
				UpgradeCardData.EffectType.COMBO_MULTIPLIER: 1
			},
			["bullet_time_1"]
		)
	),
]

var selectable_cards: Array[UpgradeCardData] = []

var _lock_cursor: bool = false
var _card_pool: Array[UpgradeCardData] = available_cards.duplicate_deep()

@onready var card_container: Control = %CardContainer
@onready var _cursor: Node2D = %Cursor
@onready var _cursor_end_position: Node2D = %CursorEndPosition
@onready var _cursor_start_position: Node2D = %CursorStartPosition


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
		if child is UpgradeCard or child is UpgradeCardMenu:
			child.card_selected.connect(_on_card_selected.bind(child.get_index()))
	_pick_cards(3)

	_lock_cursor = true
	_cursor.position = _cursor_start_position.position
	await (
		create_tween()
		. tween_property(_cursor, "position", get_local_mouse_position(), 0.2)
		. set_trans(Tween.TRANS_LINEAR)
		. set_ease(Tween.EASE_IN_OUT)
		. finished
	)
	_lock_cursor = false


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_card_selected(card_data: UpgradeCardData, index: int) -> void:
	print("Card selected: %s" % card_data.title)
	if !(get_parent().name == "MainMenu"):
		var applied = GameState.apply_upgrade(card_data)
		if not applied:
			return

	var card = card_container.get_child(index)
	if card != null:
		_lock_cursor = true
		card.signature_point_added.connect(
			func(point: Vector2) -> void:
				# _cursor.position = card.position + point
				(
					create_tween()
					. tween_property(_cursor, "global_position", card.global_position + point, 0.05)
					. set_trans(Tween.TRANS_LINEAR)
				)
		)

		await card.sign_contract()

	await (
		create_tween()
		. tween_property(_cursor, "position", _cursor_end_position.position, 0.5)
		. set_trans(Tween.TRANS_LINEAR)
		. set_ease(Tween.EASE_OUT)
		. finished
	)

	if get_parent().name == "MainMenu":
		if index == 0:
			Globals.end_scene(Globals.EndSceneStatus.MAIN_MENU_CLICK_START)
		elif index == 1:
			Globals.end_scene(Globals.EndSceneStatus.MAIN_MENU_CLICK_CREDITS)
		elif index == 2:
			Globals.end_scene(Globals.EndSceneStatus.MAIN_MENU_CLICK_QUIT)
		return

	selectable_cards.pop_at(index)
	_reset_selectable_cards()
	emit_signal("close")
	_lock_cursor = false


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
	if not _lock_cursor:
		_cursor.position = get_local_mouse_position()


func _on_skip_button_button_up() -> void:
	emit_signal("close")
