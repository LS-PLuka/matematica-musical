extends Control

const DIALOG_SCREEN = preload("res://scenes/ui/dialog_screen.tscn")
const DURACAO_FADE := 0.8
const PROXIMA_CENA := "res://scenes/ui/menu_principal.tscn"

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var hud: CanvasLayer = $HUD

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

func _ready() -> void:
	$Background.visible = false
	video_player.finished.connect(_ao_terminar_video)
	video_player.play()

func _unhandled_input(_event: InputEvent) -> void:
	# Escape só funciona enquanto o diálogo NÃO começou
	if Input.is_action_just_pressed("ui_cancel") and not _dialogo_iniciado:
		_pular_para_dialogo()

func _pular_para_dialogo() -> void:
	# Para o vídeo e inicia o diálogo direto
	video_player.stop()
	_ao_terminar_video()

func _ao_terminar_video() -> void:
	_dialogo_iniciado = true
	set_process_unhandled_input(false)
	video_player.visible = false
	$Background.visible = true
	
	var dialog: DialogScreen = DIALOG_SCREEN.instantiate()
	dialog.data = _dialog_data
	dialog.dialogo_finalizado.connect(_ao_terminar_dialogo)
	hud.add_child(dialog)

func _ao_terminar_dialogo() -> void:
	SceneManager.ir_para(PROXIMA_CENA)
