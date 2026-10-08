extends Control


func _ready() -> void:
	QuizManager.question_loaded.connect(_on_question_loaded)
	QuizManager.answer_correct.connect(_on_answer_correct)
	QuizManager.answer_wrong.connect(_on_answer_wrong)
	QuizManager.quiz_completed.connect(_on_quiz_completed)

	%ButtonHint.pressed.connect(_on_hint_pressed)
	%ButtonA.pressed.connect(func(): QuizManager.submit_answer("A"))
	%ButtonB.pressed.connect(func(): QuizManager.submit_answer("B"))
	%ButtonC.pressed.connect(func(): QuizManager.submit_answer("C"))
	%ButtonContinue.pressed.connect(_on_continue_pressed)

	QuizManager.load_quiz("res://data/quizzes/quiz_ato_ii.json")


func _on_hint_pressed() -> void:
	if has_node("%HintContainer"):
		%HintContainer.visible = true
	%HintLabel.visible = true


func _on_question_loaded(data: Dictionary) -> void:
	%QuizLabel.text = data["text"]
	%HintLabel.text = "💡 DICA: " + data["hint"]
	%DifficultyLabel.text = "DIFICULDADE: " + str(data.get("level", "INICIANTE")).to_upper()
	%ButtonA.text = "[A] " + data["options"][0]["text"]
	%ButtonB.text = "[B] " + data["options"][1]["text"]
	%ButtonC.text = "[C] " + data["options"][2]["text"]


func _on_answer_correct(feedback: String) -> void:
	%FeedbackLabel.text = "✔ CORRETO! " + feedback
	%FeedbackLabel.add_theme_color_override("font_color", Color(0.35, 1.0, 0.6, 1.0))
	if has_node("%FeedbackPanel"):
		%FeedbackPanel.visible = true
	%FeedbackLabel.visible = true
	%ButtonContinue.visible = true
	%ButtonContinue.grab_focus()
	_set_answers_visible(false)


func _on_answer_wrong(feedback: String) -> void:
	%FeedbackLabel.text = "✖ OPS! " + feedback
	%FeedbackLabel.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	if has_node("%FeedbackPanel"):
		%FeedbackPanel.visible = true
	%FeedbackLabel.visible = true


func _on_continue_pressed() -> void:
	if has_node("%HintContainer"):
		%HintContainer.visible = false
	%HintLabel.visible = false
	%ButtonContinue.visible = false
	if has_node("%FeedbackPanel"):
		%FeedbackPanel.visible = false
	%FeedbackLabel.visible = false
	_set_answers_visible(true)
	%ButtonA.grab_focus()
	QuizManager._load_current()


func _on_quiz_completed() -> void:
	if is_instance_valid(SceneManager):
		SceneManager.ir_para("res://scenes/gameplay/rhythm/rhythm.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/gameplay/rhythm/rhythm.tscn")


func _set_answers_visible(value: bool) -> void:
	if has_node("%Answers"):
		%Answers.visible = value
	%ButtonA.visible = value
	%ButtonB.visible = value
	%ButtonC.visible = value
