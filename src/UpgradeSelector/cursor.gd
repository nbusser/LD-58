class_name Cursor

extends Node2D

const CURSOR_START_POSITION: Vector2 = Vector2(832.0, 1045.0)
const CURSOR_END_POSITION: Vector2 = Vector2(1667.0, 371.0)

var _is_locked = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	_is_locked = true
	global_position = CURSOR_START_POSITION
	await (
		create_tween()
		.tween_property(self, "global_position", get_global_mouse_position(), 0.2)
		.set_trans(Tween.TRANS_LINEAR)
		.set_ease(Tween.EASE_IN_OUT)
		.finished
	)
	_is_locked = false

func _process(_delta: float):
	if not _is_locked:
		global_position = get_global_mouse_position()


func _sign_card(card: UpgradeCard):
	_is_locked = true
	card.signature_point_added.connect(
		func(point: Vector2) -> void:
			# position = card.position + point
			(
				create_tween()
				.tween_property(self, "global_position", card.global_position + point, 0.05)
				.set_trans(Tween.TRANS_LINEAR)
			)
	)
	
	await card.sign_contract()

	await (
		create_tween()
		. tween_property(self, "global_position", CURSOR_END_POSITION, 0.5)
		. set_trans(Tween.TRANS_LINEAR)
		. set_ease(Tween.EASE_OUT)
		. finished
	)

	_is_locked = false
