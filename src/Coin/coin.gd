class_name Coin
extends RigidBody2D


var impulse_force := Vector2(0, 0)


func init(spawn_position):
	self.global_position = spawn_position
	$AnimationPlayer.play("blink")


func _on_despawn_timer_timeout() -> void:
	self.queue_free()


func propulse_up(dist_proportion):
	apply_impulse(dist_proportion * Vector2(0, -250))
