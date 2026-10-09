extends Control
class_name CreditosScreen

const PROXIMA_CENA := "res://scenes/ui/menu_principal.tscn" 

const CAMINHO_FONTE := "res://assets/fonts/joystix monospace.otf" 
# Se você tiver um arquivo de shader VHS (ex: vhs_crt.gdshader), coloque o caminho aqui:
const CAMINHO_SHADER := "res://assets/shaders/VHS.gdshader" 

const VELOCIDADE_NORMAL := 55.0
const VELOCIDADE_RAPIDA := 220.0

const TAMANHO_TITULO_JOGO := 36
const TAMANHO_SECAO := 26
const TAMANHO_NOME := 20
const ESPACO_ENTRE_SECOES := 56
const COR_SECAO := Color("f2c14e")
const COR_NOME := Color.WHITE

const CREDITOS: Array[Dictionary] = [
	{"titulo": "Direção de Jogo", "nomes": ["Gabriel Cassiano", "Lucas Cury"]},
	{"titulo": "Programação", "nomes": ["Daniel Custódio", "Gianluca Zocarato", "João Vitor Simões", "Pedro Luka Silva"]},
	{"titulo": "Arte e Animação", "nomes": ["Matheus Henrique Nascimento"]},
	{"titulo": "Música e Sound Design", "nomes": ["Gabriel Cassiano"]},
	{"titulo": "Roteiro e Pedagogia Musical", "nomes": ["Gabriel Cassiano", "Lucas Cury"]},
	{"titulo": "Agradecimentos", "nomes": ["FATEC", "Game Jam 2026", "Maestro Bit"]},
]

@onready var conteudo: VBoxContainer = $VBoxContainer

var _rolando: bool = false
var _encerrando: bool = false

var fonte_personalizada = load(CAMINHO_FONTE)

func _ready() -> void:
	if has_node("VBoxContainer/Label"):
		$VBoxContainer/Label.queue_free()
		
	# Adiciona o efeito VHS/CRT dinamicamente por código cobrindo toda a tela por cima
	_adicionar_efeito_vhs()
	
	_montar_creditos()
	
	await get_tree().process_frame
	conteudo.custom_minimum_size.x = 1152
	conteudo.position = Vector2(0.0, 648.0)
	_rolando = true

func _process(delta: float) -> void:
	if not _rolando:
		return

	var velocidade := VELOCIDADE_RAPIDA if Input.is_action_pressed("ui_accept") else VELOCIDADE_NORMAL
	conteudo.position.y -= velocidade * delta

	if conteudo.position.y + conteudo.size.y < 0.0:
		_encerrar()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_encerrar()

func _montar_creditos() -> void:
	_adicionar_label("PERDIDO NO MUNDO DA MATEMÚSICA", TAMANHO_TITULO_JOGO, COR_SECAO)
	_adicionar_espaco(ESPACO_ENTRE_SECOES)

	for secao: Dictionary in CREDITOS:
		_adicionar_label(secao["titulo"], TAMANHO_SECAO, COR_SECAO)
		for nome: String in secao["nomes"]:
			_adicionar_label(nome, TAMANHO_NOME, COR_NOME)
		_adicionar_espaco(ESPACO_ENTRE_SECOES)

	_adicionar_label("Obrigado por jogar!", TAMANHO_SECAO, COR_SECAO)
	_adicionar_espaco(20)
	_adicionar_label("[Pressione ESC ou clique para voltar]", 18, Color.GRAY)

func _adicionar_label(texto: String, tamanho: int, cor: Color) -> void:
	var label := Label.new()
	label.text = texto
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	if fonte_personalizada:
		label.add_theme_font_override("font", fonte_personalizada)
		
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	
	conteudo.add_child(label)

func _adicionar_espaco(altura: int) -> void:
	var espaco := Control.new()
	espaco.custom_minimum_size.y = altura
	conteudo.add_child(espaco)

func _adicionar_efeito_vhs() -> void:
	var vhs_rect := ColorRect.new()
	vhs_rect.name = "FiltroVHS"
	
	# Faz o ColorRect ocupar a tela inteira (Full Rect)
	vhs_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Importante: mouse_filter como IGNORE para que os cliques atravessem o filtro e fechem os créditos
	vhs_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	# Se você tiver um arquivo de shader pronto, aplica ele aqui:
	if ResourceLoader.exists(CAMINHO_SHADER):
		var shader_file = load(CAMINHO_SHADER)
		var material := ShaderMaterial.new()
		material.shader = shader_file
		vhs_rect.material = material
	else:
		# Fallback simples: deixa uma película escura transparente caso não ache o shader
		vhs_rect.color = Color(0, 0, 0, 0.15) 
		
	# Adiciona por último na cena para garantir que fique na camada superior (por cima do texto)
	add_child(vhs_rect)

func _encerrar() -> void:
	if _encerrando:
		return
	_encerrando = true
	_rolando = false
	SceneManager.ir_para(PROXIMA_CENA)
