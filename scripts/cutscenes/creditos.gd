extends Control

func _ready() -> void:
	$VideoStreamPlayer.finished.connect(_ao_terminar)
	$VideoStreamPlayer.play()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_ao_terminar()

func _ao_terminar() -> void:
	set_process_unhandled_input(false)
	SceneManager.ir_para("res://scenes/ui/menu_principal.tscn")
