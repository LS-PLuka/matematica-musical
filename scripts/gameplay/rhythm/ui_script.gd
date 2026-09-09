extends Control



@export var score : int = 0000
@export var score_value_label : Label

func update_score(score_receive : int):
	score += score_receive
	score_value_label.text = String.num(score, 0)
