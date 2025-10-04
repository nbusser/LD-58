class_name Player

extends CharacterBody2D

@export var speed = 400

func _ready() -> void:
	# Waits for Game.gd to run randomize()
	await get_tree().process_frame

func get_input():
	var input_direction = Input.get_axis("move_left", "move_right")
	velocity = Vector2(input_direction * speed, 0)

func _physics_process(_delta):
	get_input()
	move_and_slide()
