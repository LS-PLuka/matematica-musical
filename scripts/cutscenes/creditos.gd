extends Control
class_name CreditosScreen

const PROXIMA_CENA := "res://scenes/ui/menu_principal.tscn" 

const CAMINHO_FONTE := "res://assets/fonts/joystix monospace.otf" 
const CAMINHO_SHADER := "res://assets/shaders/VHS.gdshader" 
const CAMINHO_LOGO := "res://assets/sprites/ui/logo_matemusica.svg" 
# >>> COLOQUE O CAMINHO EXATO DA LOGO DA FATEC AQUI <<<
const CAMINHO_LOGO_FATEC := "res://assets/sprites/ui/fatec_sao_sebastiao.png"

const VELOCIDADE_NORMAL := 55.0
const VELOCIDADE_RAPIDA := 220.0

const TAMANHO_SECAO := 28
const TAMANHO_NOME := 22
const ESPACO_ENTRE_SECOES := 56
const COR_SECAO := Color("f2c14e")
const COR_NOME := Color.WHITE

const CREDITOS: Array[Dictionary] = [
	{"titulo": "Direção de Jogo", "nomes": ["Gabriel Cassiano", "Lucas Cury"]},
	{"titulo": "Programação", "nomes": ["Daniel Custódio", "Gianluca Zocarato", "João Vitor Simões", "Pedro Luka Silva"]},
	{"titulo": "Arte e Animação", "nomes": ["Matheus Henrique Nascimento"]},
	{"titulo": "Música e Sound Design", "nomes": ["Gabriel Cassiano"]},
	{"titulo": "Roteiro e Pedagogia Musical", "nomes": ["Gabriel Cassiano", "Lucas Cury"]},
	{"titulo": "Agradecimentos", "nomes": ["FATEC", "Expo Game Jam 2026", "Maestro Bit"]},
]

@onready var conteudo: VBoxContainer = $VBoxContainer

var _rolando: bool = false
var _encerrando: bool = false

var fonte_personalizada = load(CAMINHO_FONTE)

func _ready() -> void:
	if has_node("VBoxContainer/Label"):
		$VBoxContainer/Label.queue_free()
		
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
	_adicionar_logo()
	_adicionar_espaco(ESPACO_ENTRE_SECOES)

	for secao: Dictionary in CREDITOS:
		_adicionar_label(secao["titulo"], TAMANHO_SECAO, COR_SECAO)
		for item: String in secao["nomes"]:
			# Se o item for "FATEC", renderiza o asset da logo em vez de texto
			if item == "FATEC":
				_adicionar_imagem_fatec()
			else:
				_adicionar_label(item, TAMANHO_NOME, COR_NOME)
		_adicionar_espaco(ESPACO_ENTRE_SECOES)

	_adicionar_label("Obrigado por jogar!", TAMANHO_SECAO, COR_SECAO)
	_adicionar_espaco(20)
	_adicionar_label("[Pressione ESC ou clique para voltar]", 18, Color.GRAY)

func _adicionar_logo() -> void:
	if ResourceLoader.exists(CAMINHO_LOGO):
		var textura_logo = load(CAMINHO_LOGO)
		var texture_rect := TextureRect.new()
		texture_rect.texture = textura_logo
		texture_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(240, 90)
		conteudo.add_child(texture_rect)

func _adicionar_imagem_fatec() -> void:
	if ResourceLoader.exists(CAMINHO_LOGO_FATEC):
		var textura_fatec = load(CAMINHO_LOGO_FATEC)
		var texture_rect := TextureRect.new()
		texture_rect.texture = textura_fatec
		
		# Permite que o TextureRect redimensione livremente baseado no custom_minimum_size
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Força o alinhamento ao centro do VBoxContainer para não ficar desalinhado
		texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		# Agora o tamanho que você definir aqui será rigorosamente obedecido:
		texture_rect.custom_minimum_size = Vector2(420, 140) # Ajuste se quiser um pouco maior ou menor
		
		conteudo.add_child(texture_rect)
	else:
		# Fallback caso a imagem não seja encontrada, exibe em texto
		_adicionar_label("FATEC", TAMANHO_NOME, COR_NOME)

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
	vhs_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vhs_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	if ResourceLoader.exists(CAMINHO_SHADER):
		var shader_file = load(CAMINHO_SHADER)
		var material := ShaderMaterial.new()
		material.shader = shader_file
		vhs_rect.material = material
	else:
		vhs_rect.color = Color(0, 0, 0, 0.15) 
		
	add_child(vhs_rect)

func _encerrar() -> void:
	if _encerrando:
		return
	_encerrando = true
	_rolando = false
	SceneManager.ir_para(PROXIMA_CENA)
