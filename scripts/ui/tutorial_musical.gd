extends Node2D

@onready var painel_lousa = $PainelLousa
@onready var painel_pizza = $PainelPizza
@onready var fala_label = $DialogoMaestro/Fala

@onready var label_titulo = $PainelLousa/VBox/LabelTitulo
@onready var label_semibreve = $PainelLousa/VBox/LabelSemiBreve
@onready var label_minima = $PainelLousa/VBox/LabelMinima
@onready var label_seminima = $PainelLousa/VBox/LabelSemiMinima
@onready var label_colcheia = $PainelLousa/VBox/LabelColcheia
@onready var label_dica = $PainelLousa/VBox/LabelDica

@onready var texto_pizza = $PainelPizza/TextoPizza

const FALAS = [
	"Preste muita atenção nessas instruções e tente memorizar o valor de cada figura musical. Só assim você será capaz de superar os desafios e chegar à Grande Partitura!",
	"Nhac! Imagine que o compasso é uma pizza de 4 fatias. Assim, a semibreve é a pizza completa (4 fatias), a mínima é a metade (2 fatias), a semínima equivale a 1 fatia e a colcheia é igual a metade de uma fatia.",
	"Deu fome?!"
]

var fala_atual = 0

func _ready():
	painel_lousa.visible = false
	painel_pizza.visible = false
	
	label_titulo.text = "Figuras Musicais:"
	label_semibreve.text = "Semibreve (O) = 4 tempos"
	label_minima.text = "Mínima = 2 tempos"
	label_seminima.text = "Semínima = 1 tempo"
	label_colcheia.text = "Colcheia = 0,5 tempo"
	label_dica.text = "Dica: use os dedos da mão para contar!"
	
	texto_pizza.text = FALAS[1]
	texto_pizza.visible = false
	
	fala_label.text = FALAS[0]

func avancar():
	fala_atual += 1
	match fala_atual:
		1:
			# mostra lousa com as figuras e dica
			painel_lousa.visible = true
		2:
			# esconde lousa, mostra pizza
			painel_lousa.visible = false
			painel_pizza.visible = true
			fala_label.text = FALAS[1]
		3:
			fala_label.text = FALAS[2]
		4:
			# quiz
			get_tree().change_scene_to_file("res://scenes/gameplay/quiz/quiz.tscn")
