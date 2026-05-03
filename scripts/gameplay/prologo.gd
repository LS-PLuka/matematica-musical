extends Node2D
class_name  Level

const _DIALOG_SCREEN: PackedScene = preload("res://scenes/ui/dialog_screen.tscn")

var _dialogo_iniciado: bool = false
var _dialog_data: Dictionary = {
	0: {
		"faceset": "res://assets/sprites/characters/portrait_temporary_1.png",
		"dialog": "Minha bateria social tá acabando e eu nem achei uma tomada de três pinos nesse quarto... Que tédio.",
		"title": "Jogador"
	},
	
	1: {
		"faceset": "res://assets/sprites/characters/portrait_temporary_1.png",
		"dialog": "Alguém me explica por que esse 'Spotify' de plástico redondo risca tanto? Deixa eu ver se isso ainda liga...",
		"title": "Jogador"
	},
}

@export_category("Objects")
@export var _hud: CanvasLayer = null

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_select") and not _dialogo_iniciado:
		_dialogo_iniciado = true
		var _new_dialog: DialogScreen = _DIALOG_SCREEN.instantiate()
		_new_dialog.data = _dialog_data
		_hud.add_child(_new_dialog)
