class_name Coin
extends RigidBody2D


func init(spawn_position):
	self.global_position = spawn_position
	$AnimationPlayer.play("blink")


func _on_despawn_timer_timeout() -> void:
	self.queue_free()
