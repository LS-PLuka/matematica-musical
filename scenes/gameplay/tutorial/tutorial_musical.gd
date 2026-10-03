extends Control

const DIALOG_SCREEN = preload("res://scenes/ui/dialog_screen.tscn")
const PROXIMA_CENA := "res://scenes/gameplay/quiz/quiz_screen.tscn"

@onready var hud: CanvasLayer = $HUD
@onready var background: TextureRect = $Background
@onready var background_lousa: TextureRect = $Background_lousa
@onready var painel_lousa: Control = $HUD/PainelLousa
@onready var painel_pizza: Control = $HUD/PainelPizza

var _dialogo_introducao: Dictionary = {
	0: {
		"faceset": "res://assets/sprites/characters/portrait_maestro.png",
		"dialog": "Saudações, viajante da era do streaming! Pronto para codificar uns acordes?",
		"title": "Maestro Bit"
	},
	1: {
		"faceset": "res://assets/sprites/characters/portrait_main.png",
		"dialog": "Isso aqui é 8-bit ou meu gráfico que bugou de vez? Tudo aqui parece velho... Meus olhos estão em 480p.",
		"title": "Jogador"
	},
	2: {
		"faceset": "res://assets/sprites/characters/portrait_maestro.png",
		"dialog": "Não se assuste, jovem! Você está no núcleo do sistema. Nos computadores tudo começa com um bit. Na música… tudo começa com um beat.",
		"title": "Maestro Bit"
	},
	3: {
		"faceset": "res://assets/sprites/characters/portrait_maestro.png",
		"dialog": "Para voltar ao seu mundo de fibra óptica, você precisará consertar a Grande Partitura. E lembre-se: a matemática é a música da mente; a música é a matemática do coração.",
		"title": "Maestro Bit"
	},
	4: {
		"faceset": "res://assets/sprites/characters/portrait_maestro.png",
		"dialog": "Preste muita atenção nessas instruções e tente memorizar o valor de cada figura musical. Só assim você será capaz de superar os desafios e chegar à Grande Partitura!",
		"title": "Maestro Bit"
	},
	5: {
		"faceset": "res://assets/sprites/characters/portrait_maestro.png",
		"dialog": "Nhac! Imagine que o compasso é uma pizza de 4 fatias. Assim, a semibreve é a pizza completa (4 fatias), a mínima é a metade (2 fatias), a semínima equivale a 1 fatia e a colcheia é igual a metade de uma fatia.",
		"title": "Maestro Bit"
	},
	6: {
		"faceset": "res://assets/sprites/characters/portrait_maestro.png",
		"dialog": "Deu fome?!",
		"title": "Maestro Bit"
	},
}

func _ready() -> void:
	background.visible = true
	background_lousa.visible = false
	painel_lousa.visible = false
	painel_pizza.visible = false
	
	_iniciar_dialogo(_dialogo_introducao)

func _iniciar_dialogo(dados_dialogo: Dictionary) -> void:
	var dialog: DialogScreen = DIALOG_SCREEN.instantiate()
	dialog.data = dados_dialogo
	
	dialog.passou_de_fala.connect(_ao_mudar_fala)
	dialog.dialogo_finalizado.connect(_ao_terminar_dialogo)
	
	hud.add_child(dialog)

func _ao_mudar_fala(i: int) -> void:
	if i >= 4:
		background.visible = false
		background_lousa.visible = true
		painel_lousa.visible = true
	else:
		background.visible = true
		background_lousa.visible = false
		painel_lousa.visible = false
	
	painel_pizza.visible = (i >= 5)

func _ao_terminar_dialogo() -> void:
	SceneManager.ir_para(PROXIMA_CENA)
