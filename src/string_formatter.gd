@tool
extends Node


func format_currency(
	amount: float, include_cents: bool = false, currency_symbol: String = "$"
) -> String:
	var regex = RegEx.new()
	regex.compile("(?<=\\d)(?=(\\d{3})+(?!\\d))")

	var formatted_amount = regex.sub(
		"%.2f" % amount if include_cents else "%.0f" % amount, ",", true
	)
	regex.search(formatted_amount)
	return "%s%s" % [currency_symbol, formatted_amount]
