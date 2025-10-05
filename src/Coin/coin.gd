class_name Coin
extends RigidBody2D

var impulse_force := Vector2(0, 0)
var _collectible_type := Collectible.CollectibleType.DOLLAR_COIN


func init(spawn_position, collectible_type: Collectible.CollectibleType) -> void:
	self.global_position = spawn_position
	self._collectible_type = collectible_type
	%Sprite2D.texture = Collectible.get_collectible_texture(collectible_type)
	$AnimationPlayer.play("blink")
	$RotationAnimationPlayer.play("rotate")


func _on_despawn_timer_timeout() -> void:
	self.queue_free()


func propulse_up(dist_proportion):
	apply_impulse(dist_proportion * Vector2(0, -150))


func get_collectible_type() -> Collectible.CollectibleType:
	return _collectible_type
