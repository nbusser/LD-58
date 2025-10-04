class_name HUD

extends Control

var level_name:
	set = set_level_name

var nb_coins:
	set = set_nb_coins

var level_number:
	set = set_level_number

var billionaire_net_worth:
	set = set_billionaire_net_worth

@onready var level_number_label: Label = $VBoxContainer/VBoxContainer/LevelNumber/LevelNumberValue
@onready var coins_label: Label = $VBoxContainer/VBoxContainer/CoinNumber/CoinNumberValue
@onready var level_name_label: Label = $VBoxContainer/CenterContainer/LevelNameValue
@onready var net_worth_label: Label = $VBoxContainer/VBoxContainer/NetWorth/NetWorthValue
@onready var dash_progress_bar: ProgressBar = $VBoxContainer/VBoxContainer/DashCooldown/ProgressBar
@onready var fadein_pane: ColorRect = $FadeinPane


func set_level_name(value: String) -> void:
	level_name_label.text = value


func set_nb_coins(value: int) -> void:
	coins_label.text = str(value)


func set_level_number(value: int) -> void:
	level_number_label.text = str(value)


func set_billionaire_net_worth(value: int) -> void:
	net_worth_label.text = str(value)


func set_dash_cooldown(value: int) -> void:
	dash_progress_bar.value = value


func init(level_state: LevelState) -> void:
	level_name = level_state.level_data.name
	level_number = level_state.level_number
	nb_coins = level_state.nb_coins
	billionaire_net_worth = level_state.billionaire_net_worth


func _ready() -> void:
	# Fadein animation
	fadein_pane.visible = 1
	create_tween().tween_property(fadein_pane, "modulate", Color.TRANSPARENT, 0.7)
