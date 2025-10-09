class_name Bubble

extends Area2D

enum Size { SMALL, MEDIUM, LARGE }

const _EXPLOSION_FRAME = 37

@export var size: Size = Size.SMALL

@onready var _bubble_anim_resource_dict: Dictionary[Size, SpriteFrames] = {
	Size.SMALL: preload("res://src/Billionaire/bubble_100.tres"),
	Size.MEDIUM: preload("res://src/Billionaire/bubble_200.tres"),
	Size.LARGE: preload("res://src/Billionaire/bubble_300.tres")
}

@onready var _sprite: AnimatedSprite2D = $Sprite


func _reset():
	visible = false
	monitorable = false
	monitoring = false


func _ready() -> void:
	_sprite.sprite_frames = _bubble_anim_resource_dict[size]


func spawn(free_at_the_end: bool = false) -> void:
	visible = true
	_sprite.play("default")

	# Waiting for bubble to explode
	while _sprite.frame != _EXPLOSION_FRAME:
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
