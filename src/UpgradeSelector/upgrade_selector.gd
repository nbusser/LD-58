extends Control

signal card_selected

@export var available_cards: Array[UpgradeCardData] = []

var selectable_cards: Array[UpgradeCardData] = []
var _card_pool: Array[UpgradeCardData] = available_cards.duplicate_deep()


func _reset_selectable_cards() -> void:
	_card_pool.append_array(selectable_cards)
	selectable_cards.clear()


func _pick_cards(nb_cards: int) -> Array[UpgradeCardData]:
	_reset_selectable_cards()

	var cards: Array[UpgradeCardData] = []

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(nb_cards):
		if _card_pool.size() == 0:
			break
		var index = rng.randi_range(0, _card_pool.size() - 1)
		cards.append(_card_pool.pop_at(index))

	return cards


func _ready():
	selectable_cards = _pick_cards(3)


func _on_card_selected(index: int) -> void:
	var card = selectable_cards[index]
	emit_signal("card_selected", card)
	selectable_cards.pop_at(index)
	_reset_selectable_cards()
