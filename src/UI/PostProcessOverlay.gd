class_name PostProcessOverlay

extends ColorRect

@export var fade_duration := 0.2
@export var desaturate_strength := .1
@export var overlay_strength := 0.15

var _tween: Tween
var _amount := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	if material:
		material.set_shader_parameter("desaturate_amount", 0.0)
		material.set_shader_parameter("overlay_amount", 0.0)
	Globals.slowmo_state_changed.connect(_on_slowmo_state_changed)
	var active := Globals.slowmos.size() > 0
	_set_amount(desaturate_strength if active else 0.0)


func _on_slowmo_state_changed(is_active: bool) -> void:
	var tscale = Engine.time_scale
	var target = desaturate_strength * (1 / tscale) if is_active else 0.0
	_animate_to(target)


func _animate_to(target: float) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	if target > 0.0:
		visible = true
	_tween = create_tween()
	_tween.tween_method(_set_amount, _amount, target, fade_duration)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT if target > _amount else Tween.EASE_IN)
	_tween.finished.connect(_on_tween_finished)


func _set_amount(value: float) -> void:
	_amount = clamp(value, 0.0, 1.0)
	if material:
		material.set_shader_parameter("desaturate_amount", _amount)
		material.set_shader_parameter("overlay_amount", _amount * overlay_strength)
	visible = _amount > 0.001


func _on_tween_finished() -> void:
	_tween = null
	if _amount <= 0.001:
		visible = false


func _exit_tree() -> void:
	var callable := Callable(self, "_on_slowmo_state_changed")
	if Globals.slowmo_state_changed.is_connected(callable):
		Globals.slowmo_state_changed.disconnect(callable)
