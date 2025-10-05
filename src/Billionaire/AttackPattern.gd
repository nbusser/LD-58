class_name AttackPattern

extends Node

@export var attack_name: String
@export var net_worth_percent_threshold: float = 100.0
@export var cooldown: float = 0.0
@export var enabled: bool = true

var routine: Callable

@onready var _cooldown_timer: Timer = $Cooldown


func is_ready() -> bool:
	return _cooldown_timer.is_stopped()


func call_routine() -> void:
	assert(routine.is_valid(), "routine must be set manually by the parent")
	if cooldown > 0.0:
		_cooldown_timer.start(cooldown)
	await routine.call()
