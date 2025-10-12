extends Node


# Storage for a one-time use float.
class OneTimeFloat:
	var _value: float = 0.0

	func _init(value: float):
		_value = value

	func consume() -> float:
		var extracted_value = _value
		_value = 0.0
		return extracted_value
