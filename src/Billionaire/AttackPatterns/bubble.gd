@tool
class_name Bubble

extends Area2D

enum Size { SMALL, MEDIUM, LARGE }

@export_tool_button("Update Preview Size") var update_preview_size_action = _update_preview_size

@export var bubble_size: Size = Size.SMALL
@export var hitbox_side: int = 100
@export var speed_factor: float = 2.5

var _bubble_anim_preview_frame_dict: Dictionary[Size, int] = {
	Size.SMALL: 48, Size.MEDIUM: 49, Size.LARGE: 49
}

var _bubble_explosion_frame_dict: Dictionary[Size, int] = {
	Size.SMALL: 37, Size.MEDIUM: 38, Size.LARGE: 38
}

@onready var _bubble_anim_resource_dict: Dictionary[Size, SpriteFrames] = {
	Size.SMALL: preload("res://src/Billionaire/bubble_100.tres"),
	Size.MEDIUM: preload("res://src/Billionaire/bubble_200.tres"),
	Size.LARGE: preload("res://src/Billionaire/bubble_300.tres")
}

@onready var _sprite: AnimatedSprite2D = $Sprite


func _reset():
	visible = false
	_sprite.frame = 0

	monitorable = false
	monitoring = false


func _ready() -> void:
	_sprite.sprite_frames = _bubble_anim_resource_dict[bubble_size]
	_reset()


func spawn(free_at_the_end: bool = false) -> void:
	visible = true
	_sprite.play("default", speed_factor)

	# Waiting for bubble to explode
	while _sprite.frame != _bubble_explosion_frame_dict[bubble_size]:
		await _sprite.frame_changed

	$ExplosionSound.play()

	monitorable = true
	monitoring = true

	await _sprite.animation_finished

	_reset()

	if free_at_the_end:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(Globals.GROUPS_DICT[Globals.Groups.PLAYER]):
		(body as Player).get_hurt(Vector2(0, 0))


func _update_preview_size() -> void:
	visible = true
	_sprite.sprite_frames = _bubble_anim_resource_dict[bubble_size]
	_sprite.frame = _bubble_anim_preview_frame_dict[bubble_size]

	var new_shape: RectangleShape2D = RectangleShape2D.new()
	new_shape.size = Vector2(hitbox_side, hitbox_side)
	$Hitbox.shape = new_shape
