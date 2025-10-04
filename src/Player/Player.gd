class_name Player

extends CharacterBody2D

var _velocity := Vector2.ZERO

@onready var _sprite := $Sprite2D


func _ready() -> void:
	# Waits for Game.gd to run randomize()
	await get_tree().process_frame


func move(velocity_p: Vector2) -> void:
	set_velocity(velocity_p)
	move_and_slide()
	print(velocity_p)
	_velocity = velocity_p
	_sprite.rotation = lerp_angle(
		_sprite.rotation, velocity.angle(), 10.0 * get_physics_process_delta_time()
	)
