extends Control
class_name TutorialMusicalUI

## Camada de UI do tutorial musical.
## Responsabilidade única: exibir painéis e o diálogo, e avisar o script
## de gameplay quando um bloco de falas termina. Não conhece a ordem das
## etapas nem decide para onde o jogo vai depois — isso é papel do gameplay.

signal dialogo_bloco_finalizado

const DIALOG_SCREEN := preload("res://scenes/ui/dialog_screen.tscn")

@onready var painel_lousa: Control = $PainelLousa
@onready var painel_pizza: Control = $PainelPizza

@onready var label_titulo: Label = $PainelLousa/VBox/LabelTitulo
@onready var label_semibreve: Label = $PainelLousa/VBox/LabelSemiBreve
@onready var label_minima: Label = $PainelLousa/VBox/LabelMinima
@onready var label_seminima: Label = $PainelLousa/VBox/LabelSemiMinima
@onready var label_colcheia: Label = $PainelLousa/VBox/LabelColcheia
@onready var label_dica: Label = $PainelLousa/VBox/LabelDica
@onready var texto_pizza: Label = $PainelPizza/TextoPizza

var _hud: CanvasLayer
var _dialog_atual: Node

func _ready() -> void:
	painel_lousa.visible = false
	painel_pizza.visible = false
	texto_pizza.visible = false

	label_titulo.text = "Figuras Musicais:"
	label_semibreve.text = "Semibreve (O) = 4 tempos"
	label_minima.text = "Mínima = 2 tempos"
	label_seminima.text = "Semínima = 1 tempo"
	label_colcheia.text = "Colcheia = 0,5 tempo"
	label_dica.text = "Dica: use os dedos da mão para contar!"

	_hud = CanvasLayer.new()
	add_child(_hud)

func mostrar_lousa(visivel: bool) -> void:
	painel_lousa.visible = visivel

func mostrar_pizza(visivel: bool) -> void:
	painel_pizza.visible = visivel

## Instancia um bloco de diálogo a partir de um dicionário no formato
## { indice: { "faceset": String, "title": String, "dialog": String } }.
## Emite dialogo_bloco_finalizado quando o jogador termina de ler o bloco.
func iniciar_dialogo(dados: Dictionary) -> void:
	if _dialog_atual:
		_dialog_atual.queue_free()

	var dialog: DialogScreen = DIALOG_SCREEN.instantiate()
	dialog.data = dados
	dialog.dialogo_finalizado.connect(_ao_terminar_dialogo)
	_hud.add_child(dialog)
	_dialog_atual = dialog

func _ao_terminar_dialogo() -> void:
	_dialog_atual = null
	dialogo_bloco_finalizado.emit()
