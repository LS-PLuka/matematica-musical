extends Node2D

@onready var painel_lousa = $PainelLousa
@onready var painel_pizza = $PainelPizza
@onready var fala_label = $DialogoMaestro/Fala
@onready var nome_label = $DialogoMaestro/NomePersonagem

@onready var label_titulo = $PainelLousa/VBox/LabelTitulo
@onready var label_semibreve = $PainelLousa/VBox/LabelSemiBreve
@onready var label_minima = $PainelLousa/VBox/LabelMinima
@onready var label_seminima = $PainelLousa/VBox/LabelSemiMinima
@onready var label_colcheia = $PainelLousa/VBox/LabelColcheia
@onready var label_dica = $PainelLousa/VBox/LabelDica
@onready var texto_pizza = $PainelPizza/TextoPizza

const DIALOGO = [
	{"nome": "Maestro Bit", "fala": "Saudações, viajante da era do streaming! Pronto para codificar uns acordes?"},
	{"nome": "Léo", "fala": "Isso aqui é 8-bit ou meu gráfico que bugou de vez? Tudo aqui parece velho... Meus olhos estão em 480p."},
	{"nome": "Maestro Bit", "fala": "Não se assuste, jovem! Você está no núcleo do sistema. Nos computadores tudo começa com um bit. Na música… tudo começa com um beat."},
	{"nome": "Maestro Bit", "fala": "Para voltar ao seu mundo de fibra óptica, você precisará consertar a Grande Partitura. E lembre-se: a matemática é a música da mente; a música é a matemática do coração."},
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

	mostrar_dialogo(0)

func mostrar_dialogo(indice: int):
	nome_label.text = DIALOGO[indice]["nome"]
	fala_label.text = DIALOGO[indice]["fala"]

func avancar():
	fala_atual += 1
	match fala_atual:
		1, 2, 3:
			mostrar_dialogo(fala_atual)
		4:
			mostrar_dialogo(fala_atual)
			painel_lousa.visible = true
		5:
			painel_lousa.visible = false
			painel_pizza.visible = true
			mostrar_dialogo(fala_atual)
		6:
			mostrar_dialogo(fala_atual)
		7:
			get_tree().change_scene_to_file("res://scenes/gameplay/quiz/quiz_screen.tscn")
