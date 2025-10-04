class_name Coin
extends RigidBody2D

func init(position):
	self.global_position = position

func _on_despawn_timer_timeout() -> void:
	self.queue_free()
