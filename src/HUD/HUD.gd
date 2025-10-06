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
@onready var hearts_container := $VBoxContainer/CenterContainer2/HeartsContainer
@onready var Heart := preload("res://src/Hearts/Heart.tscn")


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


func update_life(health):
	for heart in hearts_container.get_children():
		if health >= 2:
			heart.value = 1
			health -= 2
		elif health == 1:
			heart.value = .5
			health -= 1
		else:
			heart.value = 0


func init(level_state: LevelState) -> void:
	level_number = level_state.level_number
	nb_coins = level_state.player_cash
	billionaire_net_worth = level_state.billionaire_net_worth


func _ready() -> void:
	# Fadein animation
	fadein_pane.visible = 1
	create_tween().tween_property(fadein_pane, "modulate", Color.TRANSPARENT, 0.7)
