extends Node
#'res://data/quizzes/quiz_ato_ii.json'

# Signals
signal question_loaded(data: Dictionary)
signal answer_wrong(feedback: String)
signal answer_correct(feedback: String)
signal quiz_completed()

var _questions: Array = []
var _current_index: int = 0
var _current_question: Dictionary = {}

func load_quiz(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)

	if not file:
		push_error("arquivo nao encontrado: " + path)
		return

	var json = JSON.new()
	json.parse(file.get_as_text())
	_questions = json.data["questions"]
	_current_index = 0
	_load_current()

func _load_current():
	if _current_index >= _questions.size():
		quiz_completed.emit()
		return
	_current_question = _questions[_current_index]
	question_loaded.emit(_current_question)

func get_hint() -> String:
	return _current_question.get("hint", "")

func submit_answer(label: String):
	for opt in _current_question["options"]:
		if label != opt["label"]:
			continue
		
		if opt["correct"]:
			answer_correct.emit(opt["feedback"])
			_current_index += 1
		else:
			answer_wrong.emit(opt["feedback"])
		return
