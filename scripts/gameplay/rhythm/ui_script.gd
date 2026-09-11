extends Control



@export var score : int = 0000
@export var score_value_label : Label
@export var last_state : Label
@export var animation : AnimationPlayer

func update_score(score_receive : int):
	score += score_receive
	score_value_label.text = String.num(score, 0)

func update_last_state(state: String):
	last_state.text = state
	var state_color : Color
	if state == "PERFECT": state_color = Color.YELLOW
	elif state == "GOOD": state_color = Color.GREEN
	else: state_color = Color.CORNFLOWER_BLUE
	
	last_state.add_theme_color_override("font_color", state_color)
	if animation.is_playing(): animation.stop()
	animation.play("pulse")
