extends Control

const DIALOG_SCREEN = preload("res://scenes/ui/dialog_screen.tscn")
const PROXIMA_CENA := "res://scenes/gameplay/quiz/quiz_screen.tscn"

@onready var hud: CanvasLayer = $HUD

var _dialog_data: Dictionary = {
	0: {
		"faceset": "res://assets/sprites/characters/portrait_npc.png",
		"dialog": "Ei! Você não deveria estar aqui a esta hora...",
		"title": "Guarda"
	},
	1: {
		"faceset": "res://assets/sprites/characters/portrait_temporary_1.png",
		"dialog": "Calma, só estou procurando o meu disco de vinil!",
		"title": "Jogador"
	}
}

func _ready() -> void:
	iniciar_dialogo()

func iniciar_dialogo() -> void:
	var dialog: DialogScreen = DIALOG_SCREEN.instantiate()
	dialog.data = _dialog_data
	
	dialog.dialogo_finalizado.connect(_ao_terminar_dialogo)
	
	hud.add_child(dialog)

func _ao_terminar_dialogo() -> void:
	SceneManager.ir_para(PROXIMA_CENA)
