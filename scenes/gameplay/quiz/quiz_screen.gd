extends Control

func _ready() -> void:
	QuizManager.question_loaded.connect(_on_question_loaded)
	QuizManager.answer_correct.connect(_on_answer_correct)
	QuizManager.answer_wrong.connect(_on_answer_wrong)
	QuizManager.quiz_completed.connect(_on_quiz_completed)
	QuizManager.load_quiz("res://data/quizzes/quiz_ato_ii.json")
	$ButtonHint.pressed.connect(_on_hint_pressed)
	$ButtonHint.text = "Dica"
	$HBoxContainer/ButtonA.pressed.connect(func(): QuizManager.submit_answer("A"))
	$HBoxContainer/ButtonB.pressed.connect(func(): QuizManager.submit_answer("B"))
	$HBoxContainer/ButtonC.pressed.connect(func(): QuizManager.submit_answer("C"))
	$ButtonContinue.visible = false
	$ButtonContinue.text = "Continuar"
	$ButtonContinue.pressed.connect(_on_continue_pressed)
	pass

func _on_hint_pressed() -> void:
	$HintLabel.visible = true

func _on_question_loaded(data: Dictionary) -> void:
	$QuizLabel.text = data["text"]
	$HintLabel.text = data["hint"]
	$DifficultyLabel.text = "Dificuldade: " + data["level"]
	$HBoxContainer/ButtonA.text = data["options"][0]["text"]
	$HBoxContainer/ButtonB.text = data["options"][1]["text"]
	$HBoxContainer/ButtonC.text = data["options"][2]["text"]
	pass

func _on_answer_correct(feedback: String) -> void:
	$FeedbackLabel.text = feedback
	$FeedbackLabel.visible = true
	$ButtonContinue.visible = true
	$HBoxContainer/ButtonA.visible = false 
	$HBoxContainer/ButtonB.visible = false
	$HBoxContainer/ButtonC.visible = false
	QuizManager._load_current()
	pass

func _on_continue_pressed() -> void:
	$HintLabel.visible = false
	$ButtonContinue.visible = false
	$FeedbackLabel.visible = false
	$HBoxContainer/ButtonA.visible = true 
	$HBoxContainer/ButtonB.visible = true
	$HBoxContainer/ButtonC.visible = true
	pass

func _on_answer_wrong(feedback: String) -> void:
	$FeedbackLabel.text = feedback
	$FeedbackLabel.visible = true
	pass

func _on_quiz_completed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")
	pass
