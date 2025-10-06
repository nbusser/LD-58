class_name HUD

extends Control

var nb_coins:
	set = set_nb_coins

var level_number:
	set = set_level_number

var billionaire_net_worth:
	set = set_billionaire_net_worth

@onready var level_number_label: Label = $VBoxContainer/VBoxContainer/LevelNumber/LevelNumberValue
@onready var coins_label: Label = $VBoxContainer/VBoxContainer/CoinNumber/CoinNumberValue
@onready var net_worth_label: Label = $VBoxContainer/VBoxContainer/NetWorth/NetWorthValue
@onready var dash_progress_bar: ProgressBar = $VBoxContainer/VBoxContainer/DashCooldown/ProgressBar
@onready var fadein_pane: ColorRect = $FadeinPane
@onready var hearts_container := $VBoxContainer/CenterContainer2/HeartsContainer
@onready var calendar_year := $Calendar/Year
@onready var calendar_month := $Calendar/Month
@onready var Heart := preload("res://src/Hearts/Heart.tscn")


func set_nb_coins(value: int) -> void:
	coins_label.text = str(value)


func set_level_number(value: int) -> void:
	level_number_label.text = str(value)


func set_billionaire_net_worth(value: int) -> void:
	net_worth_label.text = StringFormatter.format_currency(value)


func set_dash_cooldown(value: int) -> void:
	dash_progress_bar.value = value


func update_life(health):
	var animation_show = false
	for heart in hearts_container.get_children():
		if health >= 2:
			health -= 2
		elif health == 1:
			heart.play("half")
			health -= 1
			animation_show = true
		else:
			if !animation_show:
				heart.play("empty")
				animation_show = true


func init(level_state: LevelState) -> void:
	level_number = level_state.level_number
	nb_coins = level_state.player_cash
	billionaire_net_worth = level_state.billionaire_net_worth


func _ready() -> void:
	# Fadein animation
	fadein_pane.visible = 1
	set_year(Globals.year)
	create_tween().tween_property(fadein_pane, "modulate", Color.TRANSPARENT, 0.7)


func set_month(m: int):
	var month_text
	match m:
		0:
			month_text = "JAN"
		1:
			month_text = "FEB"
		2:
			month_text = "MAR"
		3:
			month_text = "APR"
		4:
			month_text = "MAY"
		5:
			month_text = "JUN"
		6:
			month_text = "JUL"
		7:
			month_text = "AUG"
		8:
			month_text = "SEP"
		9:
			month_text = "OCT"
		10:
			month_text = "NOV"
		_:
			month_text = "DEC"
	calendar_month.set_text(month_text)


func set_year(y: int):
	calendar_year.set_text(str(y))
