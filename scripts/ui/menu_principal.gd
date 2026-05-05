extends Control


@export var start: Button

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	start.grab_focus()


func _on_start_pressed() -> void:
	pass


func _on_exit_pressed() -> void:
	get_tree().quit()
