class_name Coin
extends RigidBody2D

var impulse_force := Vector2(0, 0)
var _collectible_type := Collectible.CollectibleType.DOLLAR_COIN


func init(spawn_position, collectible_type: Collectible.CollectibleType) -> void:
	self.global_position = spawn_position
	self._collectible_type = collectible_type
	$AnimationPlayer.play("blink")

	for child in $Graphics.get_children():
		child.visible = false

	match _collectible_type:
		Collectible.CollectibleType.DOLLAR_COIN:
			$IdleAnimationPlayer.play("rotate")
			$SmallCollisionShape2D.disabled = false
			%DOLLAR_COIN.visible = true
		Collectible.CollectibleType.BITCOIN:
			$IdleAnimationPlayer.play("rotate")
			$SmallCollisionShape2D.disabled = false
			%BITCOIN.visible = true
		Collectible.CollectibleType.DOLLAR_BILL:
			$IdleAnimationPlayer.play("float")
			$MediumCollisionShape2D.disabled = false
			%DOLLAR_BILL.visible = true
		Collectible.CollectibleType.BUNDLE_OF_CASH:
			$IdleAnimationPlayer.play("float")
			$MediumCollisionShape2D.disabled = false
			%BUNDLE_OF_CASH.visible = true
		Collectible.CollectibleType.MONEY_BAG:
			$IdleAnimationPlayer.play("float")
			$LargeCollisionShape2D.disabled = false
			%MONEY_BAG.visible = true
		Collectible.CollectibleType.GOLD_BAR:
			$IdleAnimationPlayer.play("float")
			$LargeCollisionShape2D.disabled = false
			%GOLD_BAR.visible = true
		_:
			$IdleAnimationPlayer.play("float")
			$SmallCollisionShape2D.disabled = false
			%Sprite2D.visible = true


func _on_despawn_timer_timeout() -> void:
	self.queue_free()


func propulse_up(dist_proportion):
	apply_impulse(dist_proportion * Vector2(0, -150))


func get_collectible_type() -> Collectible.CollectibleType:
	return _collectible_type
