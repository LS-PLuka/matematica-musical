extends Node2D

const DIALOG_SCREEN = preload("res://scenes/ui/dialog_screen.tscn")

@onready var painel_lousa = $PainelLousa
@onready var painel_pizza = $PainelPizza

@onready var label_titulo = $PainelLousa/VBox/LabelTitulo
@onready var label_semibreve = $PainelLousa/VBox/LabelSemiBreve
@onready var label_minima = $PainelLousa/VBox/LabelMinima
@onready var label_seminima = $PainelLousa/VBox/LabelSemiMinima
@onready var label_colcheia = $PainelLousa/VBox/LabelColcheia
@onready var label_dica = $PainelLousa/VBox/LabelDica

@onready var texto_pizza = $PainelPizza/TextoPizza
@onready var fala_label = $DialogoMaestro/Fala
@onready var nome_label = $DialogoMaestro/NomePersonagem

const DIALOGO_APRESENTACAO = {
	0: {"title": "Maestro Bit", "dialog": "Saudações, viajante da era do streaming! Pronto para codificar uns acordes?", "faceset": "res://assets/sprites/characters/portrait_temporary_1.png"},
	1: {"title": "Léo", "dialog": "Isso aqui é 8-bit ou meu gráfico que bugou de vez? Tudo aqui parece velho... Meus olhos estão em 480p.", "faceset": "res://assets/sprites/characters/portrait_temporary_1.png"},
	2: {"title": "Maestro Bit", "dialog": "Não se assuste, jovem! Você está no núcleo do sistema. Nos computadores tudo começa com um bit. Na música… tudo começa com um beat.", "faceset": "res://assets/sprites/characters/portrait_temporary_1.png"},
	3: {"title": "Maestro Bit", "dialog": "Para voltar ao seu mundo de fibra óptica, você precisará consertar a Grande Partitura. E lembre-se: a matemática é a música da mente; a música é a matemática do coração.", "faceset": "res://assets/sprites/characters/portrait_temporary_1.png"},
}

const FALAS_TUTORIAL = [
	{"nome": "Maestro Bit", "fala": "Preste muita atenção nessas instruções e tente memorizar o valor de cada figura musical. Só assim você será capaz de superar os desafios e chegar à Grande Partitura!"},
	{"nome": "Maestro Bit", "fala": "Nhac! Imagine que o compasso é uma pizza de 4 fatias. Assim, a semibreve é a pizza completa (4 fatias), a mínima é a metade (2 fatias), a semínima equivale a 1 fatia e a colcheia é igual a metade de uma fatia."},
	{"nome": "Maestro Bit", "fala": "Deu fome?!"},
]

var fala_atual = 0

func _ready():
	painel_lousa.visible = false
	painel_pizza.visible = false
	texto_pizza.visible = false

	label_titulo.text = "Figuras Musicais:"
	label_semibreve.text = "Semibreve (O) = 4 tempos"
	label_minima.text = "Mínima = 2 tempos"
	label_seminima.text = "Semínima = 1 tempo"
	label_colcheia.text = "Colcheia = 0,5 tempo"
	label_dica.text = "Dica: use os dedos da mão para contar!"

	_iniciar_dialogo_apresentacao()

func _iniciar_dialogo_apresentacao():
	var dialog: DialogScreen = DIALOG_SCREEN.instantiate()
	dialog.data = DIALOGO_APRESENTACAO
	dialog.dialogo_finalizado.connect(_ao_terminar_apresentacao)
	add_child(dialog)

func _ao_terminar_apresentacao():
	nome_label.text = FALAS_TUTORIAL[0]["nome"]
	fala_label.text = FALAS_TUTORIAL[0]["fala"]
	$BotaoAvancar.visible = true

func avancar():
	fala_atual += 1
	match fala_atual:
		1:
			painel_lousa.visible = true
		2:
			painel_lousa.visible = false
			painel_pizza.visible = true
			nome_label.text = FALAS_TUTORIAL[1]["nome"]
			fala_label.text = FALAS_TUTORIAL[1]["fala"]
		3:
			nome_label.text = FALAS_TUTORIAL[2]["nome"]
			fala_label.text = FALAS_TUTORIAL[2]["fala"]
		4:
			get_tree().change_scene_to_file("res://scenes/gameplay/quiz/quiz.tscn")
