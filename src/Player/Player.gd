class_name Player

extends CharacterBody2D

var _velocity := Vector2.ZERO
@export var speed = 400

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

func get_input():
	var input_direction = Input.get_axis("move_left", "move_right")
	velocity = Vector2(input_direction * speed, 0)

func _physics_process(_delta):
	get_input()
	move_and_slide()
