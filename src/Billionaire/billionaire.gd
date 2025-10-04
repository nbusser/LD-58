class_name Billionaire

extends CharacterBody2D

const GRAVITY: float = 1200.0

var _is_gravity_enabled: bool = true

@onready var _idle_timer: Timer = $IdleTimer

var _bullet_scene = preload("res://src/Bullet/Bullet.tscn")

enum BillionaireState {
	IDLE = 0,
	AIR_SHOTGUN = 1,
}

var state_to_routine: Dictionary[BillionaireState, Callable] = {
	BillionaireState.AIR_SHOTGUN: _air_shotgun_routine
}

# Return a random attack pattern
func _get_new_state() -> BillionaireState:
	var state = randi() % (BillionaireState.size() - 1) + 1 as BillionaireState
	assert(state != BillionaireState.IDLE)
	return state

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if _is_gravity_enabled:
		velocity.y += GRAVITY * delta


func _air_shotgun_routine() -> void:
	velocity.y = -600
	while velocity.y < 0:
		await get_tree().process_frame

	_is_gravity_enabled = false
	var freeze_timer := get_tree().create_timer(0.5)
	_is_gravity_enabled = true

	await freeze_timer.timeout

	var bullet: Bullet = _bullet_scene.instantiate()
	
	#TODO: get player position
	var player_position = Vector2(0.0, 0.0)
	var bullet_direction = player_position - position
	bullet.init(position, bullet_direction, 200)
	add_child(bullet)
	

func _on_idle_timer_timeout() -> void:
	var new_state: BillionaireState = _get_new_state()
	var routine: Callable = state_to_routine.get(new_state)
	await routine.call()
	_idle_timer.start()
