class_name AttackPattern

extends Node

@export var attack_name: String
@export var health_threshold: float = 100.0
@export var cooldown: float = 0.0

var routine: Callable

@onready var _cooldown_timer: Timer = $Cooldown


func call_routine() -> void:
	assert(routine.is_valid(), "routine must be set manually by the parent")
	_cooldown_timer.start(cooldown)
	await routine.call()
