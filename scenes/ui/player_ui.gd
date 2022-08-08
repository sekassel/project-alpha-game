extends Control

onready var exp_bar = get_node("NinePatchRect/ProgressBar")
onready var clock = get_node("Clock/clock")

func _ready():
	pass # Replace with function body.

# set expbar value
func set_exp(new_value):
	exp_bar.value = exp_bar.value + int(new_value)
	if exp_bar.value > exp_bar.max_value:
		Utils.get_current_player().set_level(Utils.get_current_player().get_level() +1)
		Utils.get_current_player().set_exp(0)### when new level? -> max exp for level
		exp_bar.value = 0

# clock
func set_time(new_hour, new_minute):
	clock.set_text(str("%02d" % new_hour) + ":" + str("%02d" % new_minute))
