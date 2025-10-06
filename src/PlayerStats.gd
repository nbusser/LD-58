class_name PlayerStats
extends Resource

var unlocked_dash = false
var unlocked_dash_down = false
var unlocked_wall_climbing = false
var unlocked_wall_projection = false
var unlocked_dash_bullet_time = false
var unlocked_on_demand_bullet_time = false
var unlocked_bonus_jump_after_airhit = false
var unlocked_fast_cooldown_dash = false
var unlocked_stronger_dash = false
var unlocked_higher_jumps = false
var unlocked_dash_glide = false
var max_nb_jumps = 1
var interest_rate = 0

# Beginner stats
# Movement
var ground_speed = 300
var air_speed = 150
# Horizontal dash
var dash_cooldown = 1.0
var dash_speed = 3700
var dash_window = .3
# Dash slow motion
var dash_slow_factor = 0.6
var dash_slow_time = 0.3
# Vertical dash
var down_dash_speed = 1500
var down_dash_duration = 0.20
# Jumps
var max_input_jump_time = .4
var jump_force = 6000
# Walls stickiness
var wall_stickiness = 450
var wall_jump_force = 450
var wall_jump_cooldown = .7
# Billionaire contact
var billionaire_head_bounce = 150
var billionaire_knockback = 800
var melee_damage = 100
# Dash glide
var dash_glide_window = .1
var glide_force = 3800

# End game stats
## Movement
#var ground_speed = 450
#var air_speed = 290
## Horizontal dash
#var dash_cooldown = 1.0
#var dash_speed = 3700
#var dash_window = .3
## Dash slow motion
#var dash_slow_factor = 0.6
#var dash_slow_time = 0.3
## Vertical dash
#var down_dash_speed = 1500
#var down_dash_duration = 0.20
## Jumps
#var max_input_jump_time = .4
#var jump_force = 7000
## Walls stickiness
#var wall_stickiness = 450
#var wall_jump_force = 450
#var wall_jump_cooldown = .7
## Billionaire contact
#var billionaire_head_bounce = 150
#var billionaire_knockback = 800
#var melee_damage = 100
## Dash glide
#var dash_glide_window = .1
#var glide_force = 3800

# Bullet proximity slow motion parameters
var bullet_proximity_radius = 65.0
var bullet_proximity_slow_factor = 0.8
var unlocked_bullet_proximity_slowmo = false
