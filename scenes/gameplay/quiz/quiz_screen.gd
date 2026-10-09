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


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	# Atalho rápido: Enter quando o botão Continuar estiver visível
	if %ButtonContinue.visible and (event.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)):
		%ButtonContinue.grab_focus()
		return

	# Se nenhum botão estiver focado e o jogador pressionar setas ou WASD
	var viewport = get_viewport()
	if viewport and viewport.gui_get_focus_owner() == null:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("up") or \
		   event.is_action_pressed("ui_down") or event.is_action_pressed("down") or \
		   event.is_action_pressed("ui_left") or event.is_action_pressed("left") or \
		   event.is_action_pressed("ui_right") or event.is_action_pressed("right") or \
		   event.is_action_pressed("ui_accept"):
			if %ButtonContinue.visible:
				%ButtonContinue.grab_focus()
			elif %ButtonA.visible:
				%ButtonA.grab_focus()


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
	
	# Foca automaticamente a primeira alternativa com suporte ao teclado/setinhas
	call_deferred("_focus_first_option")


func _focus_first_option() -> void:
	if %ButtonA.visible:
		%ButtonA.grab_focus()


func _on_answer_correct(feedback: String) -> void:
	%FeedbackLabel.text = "✔ CORRETO! " + feedback
	%FeedbackLabel.add_theme_color_override("font_color", Color(0.35, 1.0, 0.6, 1.0))
	if has_node("%FeedbackPanel"):
		%FeedbackPanel.visible = true
	%FeedbackLabel.visible = true
	%ButtonContinue.visible = true
	_set_answers_visible(false)
	%ButtonContinue.call_deferred("grab_focus")


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
