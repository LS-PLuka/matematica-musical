extends Control

const DIALOG_SCREEN = preload("res://scenes/ui/dialog_screen.tscn")
const DURACAO_FADE := 0.8
const PROXIMA_CENA := "res://scenes/cutscenes/creditos.tscn"

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var hud: CanvasLayer = $HUD

var _dialogo_iniciado: bool = false

var _dialog_data: Dictionary = {
	0: {
		"faceset": "res://assets/sprites/characters/portrait_maestro.png",
		"dialog": "Incrível! O ritmo está perfeitamente sincronizado e o ponteiro do compasso voltou a rodar sem falhas. Você afinou a própria lógica do sistema!",
		"title": "Maestro Bit"
	},
	1: {
		"faceset": "res://assets/sprites/characters/portrait_main.png",
		"dialog": "Consegui! Sinto que o sinal de internet está voltando... Quer dizer, o meu quarto de antes está reaparecendo!",
		"title": "Jogador"
	},
	2: {
		"faceset": "res://assets/sprites/characters/portrait_maestro.png",
		"dialog": "Ah, as maravilhas de uma boa renderização temporal! Lembre-se, jovem: nos computadores tudo começa com um bit, e na música... tudo começa com um beat.",
		"title": "Maestro Bit"
	},
	3: {
		"faceset": "res://assets/sprites/characters/portrait_maestro.png",
		"dialog": "A Grande Partitura foi restaurada. Vá em paz para o seu mundo de alta definição, mas nunca se esqueça: a matemática organiza os números da mesma forma que a música organiza o tempo.",
		"title": "Maestro Bit"
	},
	4: {
		"faceset": "res://assets/sprites/characters/portrait_maestro.png",
		"dialog": "Fim da transmissão... Ejetando o jogador de volta à realidade em 3, 2, 1... Tof! Até a próxima batida!",
		"title": "Maestro Bit"
	}
}

func _ready() -> void:
	# $Background.visible = false
	# video_player.finished.connect(_ao_terminar_video)
	# video_player.play()
	_ao_terminar_video()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and not _dialogo_iniciado:
		_pular_para_dialogo()

func _pular_para_dialogo() -> void:
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
