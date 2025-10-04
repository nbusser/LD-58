class_name Player
extends CharacterBody2D
@export var speed = 400

func _ready() -> void:
	# Waits for Game.gd to run randomize()
	await get_tree().process_frame


func get_input():
	var input_direction = Input.get_axis("move_left", "move_right")
	var jumping_speed = 0
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		jumping_speed = -speed
	velocity = Vector2(input_direction*speed, velocity.y + jumping_speed)


func _physics_process(_delta):
	get_input()
	velocity.y = velocity.y + 980*_delta
	move_and_slide()
