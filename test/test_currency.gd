@tool
extends EditorScript


func _run() -> void:
	print("Running tests...")

	print("Test 1: Basic formatting without cents")
	var result1 = StringFormatter.format_currency(1234.56)
	print("Result: %s" % result1)

	print("Test 2: Formatting with cents")
	var result2 = StringFormatter.format_currency(1234.56, true)
	print("Result: %s" % result2)

	print("Test 3: Formatting with different currency symbol")
	var result3 = StringFormatter.format_currency(1234.56, true, "€")
	print("Result: %s" % result3)

	print("Test 4: Large number formatting")
	var result4 = StringFormatter.format_currency(1234567890.12, true, "£")
	print("Result: %s" % result4)

	print("Test 5: Negative number formatting")
	var result5 = StringFormatter.format_currency(-9876.54, true, "¥")
	print("Result: %s" % result5)

	print("All tests completed.")
