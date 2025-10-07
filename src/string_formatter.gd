@tool
extends Node


func format_currency(
	amount: float,
	include_cents: bool = false,
	currency_symbol: String = "$",
	long_form: bool = false,
) -> String:
	var regex = RegEx.new()
	regex.compile("(?<=\\d)(?=(\\d{3})+(?!\\d))")

	var suffix = ""
	var value = amount

	if not long_form:
		if abs(amount) >= 1_000_000_000:
			value = amount / 1_000_000.0
			suffix = "B"
		if abs(amount) >= 1_000_000:
			value = amount / 1_000_000.0
			suffix = "M"
		elif abs(amount) >= 1_000:
			value = amount / 1_000.0
			suffix = "k"

	var formatted_value: String
	if suffix != "":
		# For short form, show 1 decimal place if needed
		if value == int(value):
			formatted_value = "%.0f" % value
		else:
			formatted_value = "%.1f" % value
	else:
		formatted_value = "%.2f" % value if include_cents else "%.0f" % value

	return "%s%s%s" % [currency_symbol, regex.sub(formatted_value, ",", true), suffix]
