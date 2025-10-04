class_name Billionaire

extends Node2D

const GRAVITY: float = 1200.0

var _is_gravity_enabled: bool = true

@onready var _idle_timer: Timer = $IdleTimer
@onready var _body: CharacterBody2D = $BillionaireBody
@onready var _bullets: Node2D = $Bullets

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
		_body.velocity.y += GRAVITY * delta
	_body.move_and_slide()

func _spawn_bullet(bullet_position: Vector2, bullet_direction: Vector2, bullet_speed: float = 100.0) -> void:
	var bullet: Bullet = _bullet_scene.instantiate()
	bullet.init(bullet_position, bullet_direction, bullet_speed)
	_bullets.add_child(bullet)

func _air_shotgun_routine() -> void:
	_body.velocity.y = -600
	while _body.velocity.y < 0:
		await get_tree().process_frame

	_is_gravity_enabled = false
	var freeze_timer := get_tree().create_timer(0.5)
	await freeze_timer.timeout
	_is_gravity_enabled = true
	
	#TODO: get player position
	var player_position = Vector2(150.0, 150.0)
	var bullet_direction = player_position - _body.position
	_spawn_bullet(_body.position, bullet_direction, 200.0)
	

func _on_idle_timer_timeout() -> void:
	var new_state: BillionaireState = _get_new_state()
	var routine: Callable = state_to_routine.get(new_state)
	await routine.call()
	_idle_timer.start()
