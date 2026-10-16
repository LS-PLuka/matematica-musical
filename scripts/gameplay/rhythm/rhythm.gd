extends Node2D

@export var falling_arrows: Node2D
@export var arrows: Node2D
@export var control: Control
@export var music_player: AudioStreamPlayer

var music_system = Music.new()
var notes: Array = []
var current_note_idx: int = 0
var active_notes: Array = []

const BPM: float = 120.0
const SPAWN_Y: float = 75.0
const TARGET_Y: float = 520.0

# Parâmetros de ritmo ajustados pela dificuldade
var fall_time: float = 3.0
var hit_tolerance_ok: float = 72.0
var hit_tolerance_good: float = 48.0
var hit_tolerance_perfect: float = 24.0
var misses_for_life_loss: int = 4

# 4 Pistas musicais centralizadas na Lousa (Lanes 0 a 3)
var lane_x: Array[float] = [376.0, 509.0, 643.0, 776.0]

const FALLING_ARROW = preload("uid://doigxdyl6f2ss")
const KEYBINDING_SCENE = preload("res://scenes/ui/keybinding_menu.tscn")

var beat_interval: float = 60.0 / BPM
var last_beat_idx: int = -1

# --- SISTEMA DE DERROTA ---
var lives: int = 3
const MAX_LIVES: int = 3
var misses_streak: int = 0
var game_over_active: bool = false
var game_won: bool = false
var paused: bool = false

# --- SISTEMA DE DESAFIO MATEMÁTICO ---
var math_challenge_active: bool = false
var math_challenge_correct_lane: int = -1
var math_challenge_timer: float = 0.0
var math_challenge_duration: float = 8.0
var math_error_penalty: float = 2.0
var errors_in_current_challenge: int = 0
var measures_since_last_challenge: int = 0
const MEASURES_PER_CHALLENGE: int = 6   # Espaçado como no mod do Hypno (FNF)
const MAX_CHALLENGES_PER_GAME: int = 3  # Máximo de 3 aparições por partida
var challenges_spawned: int = 0
var last_challenge_measure: int = -1
var _challenge_resolving: bool = false

# Desafios matemáticos graduados por dificuldade
const MATH_CHALLENGES_FACIL := [
	{"eq": "1/2 + 1/2 = ?t",     "prompt": "Qual nota vale 1 tempo?",    "lane": 2, "answer_name": "Semínima (1t)"},
	{"eq": "1 + 1 = ?t",         "prompt": "Qual nota vale 2 tempos?",   "lane": 1, "answer_name": "Mínima (2t)"},
	{"eq": "2 + 2 = ?t",         "prompt": "Qual nota vale 4 tempos?",   "lane": 0, "answer_name": "Semibreve (4t)"},
	{"eq": "4 - 2 = ?t",         "prompt": "Qual nota vale 2 tempos?",   "lane": 1, "answer_name": "Mínima (2t)"},
	{"eq": "2 - 1 = ?t",         "prompt": "Qual nota vale 1 tempo?",    "lane": 2, "answer_name": "Semínima (1t)"},
	{"eq": "1 / 2 = ?t",         "prompt": "Qual nota vale 1/2 tempo?",  "lane": 3, "answer_name": "Colcheia (1/2t)"},
	{"eq": "1 + 1 + 2 = ?t",     "prompt": "Qual nota vale 4 tempos?",   "lane": 0, "answer_name": "Semibreve (4t)"},
	{"eq": "2 / 2 = ?t",         "prompt": "Qual nota vale 1 tempo?",    "lane": 2, "answer_name": "Semínima (1t)"},
]

const MATH_CHALLENGES_NORMAL := [
	{"eq": "1/2 + 1/2 = ?t",     "prompt": "Qual nota vale 1 tempo?",    "lane": 2, "answer_name": "Semínima (1t)"},
	{"eq": "4 / 2 = ?t",         "prompt": "Qual nota vale 2 tempos?",   "lane": 1, "answer_name": "Mínima (2t)"},
	{"eq": "1 + 1 + 1 + 1 = ?t", "prompt": "Qual nota vale 4 tempos?",   "lane": 0, "answer_name": "Semibreve (4t)"},
	{"eq": "1 / 2 = ?t",         "prompt": "Qual nota vale 1/2 tempo?",  "lane": 3, "answer_name": "Colcheia (1/2t)"},
	{"eq": "2 * 2 = ?t",         "prompt": "Qual nota vale 4 tempos?",   "lane": 0, "answer_name": "Semibreve (4t)"},
	{"eq": "3 - 1 = ?t",         "prompt": "Qual nota vale 2 tempos?",   "lane": 1, "answer_name": "Mínima (2t)"},
	{"eq": "1/4 + 1/4 = ?t",     "prompt": "Qual nota vale 1/2 tempo?",  "lane": 3, "answer_name": "Colcheia (1/2t)"},
	{"eq": "2 * 1/2 = ?t",       "prompt": "Qual nota vale 1 tempo?",    "lane": 2, "answer_name": "Semínima (1t)"},
]

const MATH_CHALLENGES_DIFICIL := [
	{"eq": "3/4 + 1/4 = ?t",         "prompt": "Qual nota vale 1 tempo?",   "lane": 2, "answer_name": "Semínima (1t)"},
	{"eq": "2 - 1/2 - 1/2 = ?t",     "prompt": "Qual nota vale 1 tempo?",   "lane": 2, "answer_name": "Semínima (1t)"},
	{"eq": "4 * 1/2 = ?t",           "prompt": "Qual nota vale 2 tempos?",  "lane": 1, "answer_name": "Mínima (2t)"},
	{"eq": "1/2 + 1/4 + 1/4 = ?t",   "prompt": "Qual nota vale 1 tempo?",   "lane": 2, "answer_name": "Semínima (1t)"},
	{"eq": "3 - 1/2 - 1/2 = ?t",     "prompt": "Qual nota vale 2 tempos?",  "lane": 1, "answer_name": "Mínima (2t)"},
	{"eq": "1/8 + 1/8 + 1/4 = ?t",   "prompt": "Qual nota vale 1/2 tempo?", "lane": 3, "answer_name": "Colcheia (1/2t)"},
	{"eq": "8 / 2 = ?t",             "prompt": "Qual nota vale 4 tempos?",  "lane": 0, "answer_name": "Semibreve (4t)"},
	{"eq": "5 - 1 - 2 = ?t",         "prompt": "Qual nota vale 2 tempos?",  "lane": 1, "answer_name": "Mínima (2t)"},
]

const MATH_CHALLENGES_HARDCORE := [
	{"eq": "4 - (1/2 + 1/2 + 1) = ?t", "prompt": "Qual nota completa a conta?", "lane": 1, "answer_name": "Mínima (2t)"},
	{"eq": "(3 * 1/2) + 1/2 = ?t",     "prompt": "Qual nota vale o resultado?", "lane": 1, "answer_name": "Mínima (2t)"},
	{"eq": "(6 / 2) + 1 = ?t",         "prompt": "Qual nota vale o resultado?", "lane": 0, "answer_name": "Semibreve (4t)"},
	{"eq": "2/4 + 2/4 = ?t",           "prompt": "Qual nota vale o resultado?", "lane": 2, "answer_name": "Semínima (1t)"},
	{"eq": "(1/2 * 2) - 1/2 = ?t",     "prompt": "Qual nota vale o resultado?", "lane": 3, "answer_name": "Colcheia (1/2t)"},
	{"eq": "4 - (1 + 1 + 1) = ?t",     "prompt": "Qual nota completa o compasso?", "lane": 2, "answer_name": "Semínima (1t)"},
	{"eq": "8 * 1/2 = ?t",             "prompt": "Qual nota vale o resultado?", "lane": 0, "answer_name": "Semibreve (4t)"},
	{"eq": "2 * (1/4 + 1/4) = ?t",     "prompt": "Qual nota vale o resultado?", "lane": 2, "answer_name": "Semínima (1t)"},
]

var current_math_challenges: Array = []
var _challenge_idx_pool: Array = []

# Overlays criados em código
var _overlay_canvas: CanvasLayer
var _game_over_panel: Control
var _pause_panel: Control
var _btn_pause_resume: Button = null
var _btn_pause_keys: Button = null
var _btn_game_over_retry: Button = null
var _math_popup: Control
var _math_popup_title: Label
var _math_popup_label: Label
var _math_popup_hint: Label
var _math_timer_bar: ProgressBar
var _challenge_buttons: Array[Button] = []
var _lives_labels: Array = []
var _keybinding_instance: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_difficulty_settings()
	notes = music_system.musics[0]
	setup_receptors()
	music_player.play()
	_init_challenge_pool()
	_create_hud_overlays()

func _apply_difficulty_settings() -> void:
	var diff = GameManager.selected_difficulty if is_instance_valid(GameManager) else GameManager.Difficulty.NORMAL
	match diff:
		GameManager.Difficulty.FACIL:
			fall_time = 3.8
			hit_tolerance_perfect = 32.0
			hit_tolerance_good = 60.0
			hit_tolerance_ok = 88.0
			misses_for_life_loss = 5
			math_challenge_duration = 10.0
			math_error_penalty = 1.5
			current_math_challenges = MATH_CHALLENGES_FACIL
		GameManager.Difficulty.NORMAL:
			fall_time = 3.0
			hit_tolerance_perfect = 24.0
			hit_tolerance_good = 48.0
			hit_tolerance_ok = 72.0
			misses_for_life_loss = 4
			math_challenge_duration = 8.0
			math_error_penalty = 2.0
			current_math_challenges = MATH_CHALLENGES_NORMAL
		GameManager.Difficulty.DIFICIL:
			fall_time = 2.2
			hit_tolerance_perfect = 18.0
			hit_tolerance_good = 36.0
			hit_tolerance_ok = 52.0
			misses_for_life_loss = 3
			math_challenge_duration = 6.0
			math_error_penalty = 2.5
			current_math_challenges = MATH_CHALLENGES_DIFICIL
		GameManager.Difficulty.HARDCORE:
			fall_time = 1.6
			hit_tolerance_perfect = 12.0
			hit_tolerance_good = 24.0
			hit_tolerance_ok = 38.0
			misses_for_life_loss = 2
			math_challenge_duration = 5.0
			math_error_penalty = 3.0
			current_math_challenges = MATH_CHALLENGES_HARDCORE

# ─── RECEPTORES DE LANE ────────────────────────────────────────────────────

func _get_action_key_name(action: String, default_key: String) -> String:
	var events = InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			var keycode = (ev as InputEventKey).physical_keycode
			var kstr = OS.get_keycode_string(keycode)
			if not kstr.is_empty():
				return kstr
	return default_key

func setup_receptors() -> void:
	if not arrows:
		return

	var receptor_configs = [
		{"name": "left",  "lane": 0, "key": _get_action_key_name("left", "A"),   "arrow": "←", "fig": "Semibreve", "val": "4t", "color": Color("#FF6B9D"), "tex": "res://assets/sprites/ui/semibreve.png"},
		{"name": "down",  "lane": 1, "key": _get_action_key_name("down", "S"),   "arrow": "↓", "fig": "Mínima",    "val": "2t", "color": Color("#5CE1E6"), "tex": "res://assets/sprites/ui/minima.png"},
		{"name": "up",    "lane": 2, "key": _get_action_key_name("up", "W"),     "arrow": "↑", "fig": "Semínima",  "val": "1t", "color": Color("#FFD166"), "tex": "res://assets/sprites/ui/seminima.png"},
		{"name": "right", "lane": 3, "key": _get_action_key_name("right", "D"),  "arrow": "→", "fig": "Colcheia",  "val": "1/2t", "color": Color("#06D6A0"), "tex": "res://assets/sprites/ui/colcheia.png"}
	]

	for cfg in receptor_configs:
		var rec = arrows.find_child(cfg["name"]) as Node2D
		if rec:
			rec.position = Vector2(lane_x[cfg["lane"]], TARGET_Y)
			if rec.has_method("setup_visuals"):
				rec.lane_index      = cfg["lane"]
				rec.action_name     = cfg["name"]
				rec.key_name        = cfg["key"]
				rec.arrow_symbol    = cfg["arrow"]
				rec.note_name       = cfg["fig"]
				rec.note_value      = cfg["val"]
				rec.accent_color    = cfg["color"]
				rec.note_texture_path = cfg["tex"]
				rec.setup_visuals()

# ─── OVERLAYS (criados programaticamente) ─────────────────────────────────

func _create_hud_overlays() -> void:
	_overlay_canvas = CanvasLayer.new()
	_overlay_canvas.layer = 20
	_overlay_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay_canvas)

	_create_game_over_overlay()
	_create_pause_overlay()
	_create_math_popup()
	_create_lives_hud()
	_create_difficulty_badge()

func _create_difficulty_badge() -> void:
	var badge = Label.new()
	badge.name = "DifficultyBadge"
	badge.text = "[ %s ]" % GameManager.get_difficulty_name()
	var font = load("res://assets/fonts/joystix monospace.otf") as FontFile
	if font:
		badge.add_theme_font_override("font", font)
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", GameManager.get_difficulty_color())
	badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	badge.add_theme_constant_override("outline_size", 3)
	badge.position = Vector2(16, 12)
	_overlay_canvas.add_child(badge)

func _create_lives_hud() -> void:
	var hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hud.offset_left   = -220.0
	hud.offset_top    =   8.0
	hud.offset_right  =   0.0
	hud.offset_bottom =  36.0
	_overlay_canvas.add_child(hud)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_theme_constant_override("separation", 6)
	hud.add_child(hbox)

	var font = load("res://assets/fonts/joystix monospace.otf") as FontFile
	for i in range(MAX_LIVES):
		var lbl = Label.new()
		lbl.text = "♥"
		lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color("#FF6B9D"))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lbl.add_theme_constant_override("outline_size", 4)
		hbox.add_child(lbl)
		_lives_labels.append(lbl)

func _create_game_over_overlay() -> void:
	_game_over_panel = Control.new()
	_game_over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over_panel.visible = false
	_overlay_canvas.add_child(_game_over_panel)

	# Fundo escuro
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.82)
	_game_over_panel.add_child(bg)

	var font = load("res://assets/fonts/joystix monospace.otf") as FontFile
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left   = -260.0
	vbox.offset_top    = -180.0
	vbox.offset_right  =  260.0
	vbox.offset_bottom =  180.0
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	_game_over_panel.add_child(vbox)

	# Título
	var title = Label.new()
	title.text = "♩ FIM DE JOGO ♩"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#FF6B6B"))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 5)
	vbox.add_child(title)
	_game_over_panel.set_meta("title_label", title)

	# Subtítulo (score)
	var sub = Label.new()
	sub.text = "Pontuação Final: 0"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", font)
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color("#FFD166"))
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	sub.add_theme_constant_override("outline_size", 3)
	vbox.add_child(sub)
	_game_over_panel.set_meta("score_label", sub)

	# Compassos label
	var comp_lbl = Label.new()
	comp_lbl.text = "Compassos Fechados: 0"
	comp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comp_lbl.add_theme_font_override("font", font)
	comp_lbl.add_theme_font_size_override("font_size", 13)
	comp_lbl.add_theme_color_override("font_color", Color("#06D6A0"))
	comp_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	comp_lbl.add_theme_constant_override("outline_size", 3)
	vbox.add_child(comp_lbl)
	_game_over_panel.set_meta("compass_label", comp_lbl)

	# Separador
	vbox.add_child(HSeparator.new())

	# Botão Tentar Novamente
	var btn_retry = _make_overlay_button("↻  Tentar Novamente", Color("#5CE1E6"), font)
	vbox.add_child(btn_retry)
	btn_retry.pressed.connect(_on_retry_pressed)
	_btn_game_over_retry = btn_retry

	# Botão Menu Principal
	var btn_menu = _make_overlay_button("⌂  Menu Principal", Color("#FFD166"), font)
	vbox.add_child(btn_menu)
	btn_menu.pressed.connect(_on_menu_pressed)

	btn_retry.focus_neighbor_top = btn_retry.get_path_to(btn_menu)
	btn_retry.focus_neighbor_bottom = btn_retry.get_path_to(btn_menu)
	btn_retry.focus_previous = btn_retry.get_path_to(btn_menu)
	btn_retry.focus_next = btn_retry.get_path_to(btn_menu)
	btn_menu.focus_neighbor_top = btn_menu.get_path_to(btn_retry)
	btn_menu.focus_neighbor_bottom = btn_menu.get_path_to(btn_retry)
	btn_menu.focus_previous = btn_menu.get_path_to(btn_retry)
	btn_menu.focus_next = btn_menu.get_path_to(btn_retry)

func _create_pause_overlay() -> void:
	_pause_panel = Control.new()
	_pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.visible = false
	_overlay_canvas.add_child(_pause_panel)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.72)
	_pause_panel.add_child(bg)

	var font = load("res://assets/fonts/joystix monospace.otf") as FontFile
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left   = -220.0
	vbox.offset_top    = -180.0
	vbox.offset_right  =  220.0
	vbox.offset_bottom =  180.0
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	_pause_panel.add_child(vbox)

	var title = Label.new()
	title.text = "⏸  PAUSADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#FFD166"))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var btn_resume = _make_overlay_button("▶  Continuar  [ESC]", Color("#06D6A0"), font)
	vbox.add_child(btn_resume)
	btn_resume.pressed.connect(_on_resume_pressed)
	_btn_pause_resume = btn_resume

	var btn_keys = _make_overlay_button("⌨  Configurar Teclas", Color("#A78BFA"), font)
	vbox.add_child(btn_keys)
	btn_keys.pressed.connect(_on_config_keys_pressed)
	_btn_pause_keys = btn_keys

	var btn_retry = _make_overlay_button("↻  Reiniciar", Color("#5CE1E6"), font)
	vbox.add_child(btn_retry)
	btn_retry.pressed.connect(_on_retry_pressed)

	var btn_menu = _make_overlay_button("⌂  Menu Principal", Color("#FF6B6B"), font)
	vbox.add_child(btn_menu)
	btn_menu.pressed.connect(_on_menu_pressed)

	var pause_btns: Array[Button] = [btn_resume, btn_keys, btn_retry, btn_menu]
	for i in range(pause_btns.size()):
		var b = pause_btns[i]
		var prev = pause_btns[(i - 1 + pause_btns.size()) % pause_btns.size()]
		var nxt = pause_btns[(i + 1) % pause_btns.size()]
		b.focus_neighbor_top = b.get_path_to(prev)
		b.focus_neighbor_bottom = b.get_path_to(nxt)
		b.focus_previous = b.get_path_to(prev)
		b.focus_next = b.get_path_to(nxt)

func _create_math_popup() -> void:
	_math_popup = Control.new()
	_math_popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_math_popup.offset_left   = -370.0
	_math_popup.offset_top    =   16.0
	_math_popup.offset_right  =  370.0
	_math_popup.offset_bottom =  186.0
	_math_popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_math_popup.visible = false
	_math_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_canvas.add_child(_math_popup)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.12, 0.08, 0.95)
	style.border_color = Color("#FFD166")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 6

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_math_popup.add_child(panel)

	var font = load("res://assets/fonts/joystix monospace.otf") as FontFile
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "⚡ DESAFIO MATEMÁTICO! [08.0s] ⚡"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", font)
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color("#FFD166"))
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_lbl.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title_lbl)
	_math_popup_title = title_lbl

	_math_popup_label = Label.new()
	_math_popup_label.text = ""
	_math_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_math_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_math_popup_label.add_theme_font_override("font", font)
	_math_popup_label.add_theme_font_size_override("font_size", 15)
	_math_popup_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_math_popup_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_math_popup_label.add_theme_constant_override("outline_size", 4)
	vbox.add_child(_math_popup_label)

	_math_popup_hint = Label.new()
	_math_popup_hint.text = "Toque na nota no teclado ou clique na opção correspondente:"
	_math_popup_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_math_popup_hint.add_theme_font_override("font", font)
	_math_popup_hint.add_theme_font_size_override("font_size", 9)
	_math_popup_hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.9))
	_math_popup_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_math_popup_hint.add_theme_constant_override("outline_size", 2)
	vbox.add_child(_math_popup_hint)

	_math_timer_bar = ProgressBar.new()
	_math_timer_bar.custom_minimum_size = Vector2(0, 6)
	_math_timer_bar.max_value = 1.0
	_math_timer_bar.value = 1.0
	_math_timer_bar.show_percentage = false
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.12, 0.12, 0.8)
	bar_bg.set_corner_radius_all(3)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color("#FFD166")
	bar_fill.set_corner_radius_all(3)
	_math_timer_bar.add_theme_stylebox_override("background", bar_bg)
	_math_timer_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(_math_timer_bar)

	# Opções clicáveis para responder
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 10)
	btn_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(btn_hbox)

	_challenge_buttons.clear()
	var lane_meta = [
		{"lane": 0, "color": Color("#FF6B9D")},
		{"lane": 1, "color": Color("#5CE1E6")},
		{"lane": 2, "color": Color("#FFD166")},
		{"lane": 3, "color": Color("#06D6A0")}
	]

	for meta in lane_meta:
		var lane_idx = meta["lane"]
		var col = meta["color"]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", col)
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))

		var sn = StyleBoxFlat.new()
		sn.bg_color = Color(0.06, 0.14, 0.10, 0.95)
		sn.border_color = col
		sn.set_border_width_all(2)
		sn.set_corner_radius_all(6)
		sn.set_content_margin_all(6)

		var sh = StyleBoxFlat.new()
		sh.bg_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 1.0)
		sh.border_color = Color(1, 1, 1, 1)
		sh.set_border_width_all(2)
		sh.set_corner_radius_all(6)
		sh.set_content_margin_all(6)

		btn.add_theme_stylebox_override("normal", sn)
		btn.add_theme_stylebox_override("hover", sh)
		btn.add_theme_stylebox_override("pressed", sh)
		btn.add_theme_stylebox_override("focus", sn)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP

		btn.pressed.connect(func(): _resolve_math_challenge(lane_idx))
		btn_hbox.add_child(btn)
		_challenge_buttons.append(btn)

func _make_overlay_button(lbl_text: String, col: Color, font: FontFile) -> Button:
	var btn = Button.new()
	btn.text = lbl_text
	btn.flat = false
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	var style_n = StyleBoxFlat.new()
	style_n.bg_color = Color(0.05, 0.12, 0.09, 0.9)
	style_n.border_color = col
	style_n.set_border_width_all(2)
	style_n.set_corner_radius_all(5)
	style_n.set_content_margin_all(10)
	var style_h = StyleBoxFlat.new()
	style_h.bg_color = Color(col.r * 0.2, col.g * 0.2, col.b * 0.2, 0.95)
	style_h.border_color = Color(1, 1, 1, 0.9)
	style_h.set_border_width_all(2)
	style_h.set_corner_radius_all(5)
	style_h.set_content_margin_all(10)
	btn.add_theme_stylebox_override("normal", style_n)
	btn.add_theme_stylebox_override("hover", style_h)
	btn.add_theme_stylebox_override("pressed", style_h)
	btn.add_theme_stylebox_override("focus", style_n)
	return btn

func _update_challenge_buttons_labels() -> void:
	var lane_data = [
		{"action": "left",  "def": "A", "num": "1", "name": "Semibreve", "val": "4t"},
		{"action": "down",  "def": "S", "num": "2", "name": "Mínima",    "val": "2t"},
		{"action": "up",    "def": "W", "num": "3", "name": "Semínima",  "val": "1t"},
		{"action": "right", "def": "D", "num": "4", "name": "Colcheia",  "val": "1/2t"}
	]
	var default_colors = [Color("#FF6B9D"), Color("#5CE1E6"), Color("#FFD166"), Color("#06D6A0")]
	for i in range(_challenge_buttons.size()):
		var btn = _challenge_buttons[i]
		if btn and i < lane_data.size():
			var key = _get_action_key_name(lane_data[i]["action"], lane_data[i]["def"])
			btn.text = "[%s / %s]\n%s (%s)" % [key, lane_data[i]["num"], lane_data[i]["name"], lane_data[i]["val"]]
			btn.add_theme_color_override("font_color", default_colors[i])
			btn.scale = Vector2(1.0, 1.0)

func _highlight_challenge_button(lane: int, correct: bool) -> void:
	if lane >= 0 and lane < _challenge_buttons.size():
		var btn = _challenge_buttons[lane]
		if btn:
			var target_col = Color("#06D6A0") if correct else Color("#FF6B6B")
			btn.add_theme_color_override("font_color", target_col)
			var tw = create_tween()
			tw.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.08)
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08)
			if not correct:
				tw.tween_callback(func():
					if is_instance_valid(btn):
						var default_colors = [Color("#FF6B9D"), Color("#5CE1E6"), Color("#FFD166"), Color("#06D6A0")]
						btn.add_theme_color_override("font_color", default_colors[lane])
				)

# ─── INPUT ────────────────────────────────────────────────────────────────

func _is_arrow_key(event: InputEvent, target_key: Key) -> bool:
	if event is InputEventKey:
		return event.physical_keycode == target_key or event.keycode == target_key
	return false

# ─── INPUT ────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	# Pausa
	if event.is_action_pressed("ui_cancel"):
		if _keybinding_instance and is_instance_valid(_keybinding_instance):
			return
		_toggle_pause()
		return

	if game_over_active:
		var vp = get_viewport()
		if vp and vp.gui_get_focus_owner() == null:
			if event.is_action_pressed("ui_up") or event.is_action_pressed("up") or \
			   event.is_action_pressed("ui_down") or event.is_action_pressed("down") or \
			   event.is_action_pressed("ui_accept"):
				if _btn_game_over_retry:
					_btn_game_over_retry.grab_focus()
		return

	if paused:
		var vp = get_viewport()
		if vp and vp.gui_get_focus_owner() == null:
			if _btn_pause_resume:
				_btn_pause_resume.grab_focus()
		return

	# Se desafio matemático está ativo, processa as respostas via teclado:
	if math_challenge_active:
		var challenge_lane := -1
		if event.is_action_pressed("left") or event.is_action_pressed("ui_left") or _is_arrow_key(event, KEY_LEFT):
			challenge_lane = 0
		elif event.is_action_pressed("down") or event.is_action_pressed("ui_down") or _is_arrow_key(event, KEY_DOWN):
			challenge_lane = 1
		elif event.is_action_pressed("up") or event.is_action_pressed("ui_up") or _is_arrow_key(event, KEY_UP):
			challenge_lane = 2
		elif event.is_action_pressed("right") or event.is_action_pressed("ui_right") or _is_arrow_key(event, KEY_RIGHT):
			challenge_lane = 3
		elif event is InputEventKey:
			var keycode = (event as InputEventKey).physical_keycode
			if keycode == KEY_NONE:
				keycode = (event as InputEventKey).keycode
			if keycode == KEY_1 or keycode == KEY_KP_1 or keycode == KEY_A:
				challenge_lane = 0
			elif keycode == KEY_2 or keycode == KEY_KP_2 or keycode == KEY_S:
				challenge_lane = 1
			elif keycode == KEY_3 or keycode == KEY_KP_3 or keycode == KEY_W:
				challenge_lane = 2
			elif keycode == KEY_4 or keycode == KEY_KP_4 or keycode == KEY_D:
				challenge_lane = 3

		if challenge_lane != -1:
			_resolve_math_challenge(challenge_lane)
			get_viewport().set_input_as_handled()
		return

	if not music_player or not music_player.playing:
		return

	var lane := -1
	var action := ""
	if event.is_action_pressed("left") or event.is_action_pressed("ui_left") or _is_arrow_key(event, KEY_LEFT):
		lane = 0; action = "left"
	elif event.is_action_pressed("down") or event.is_action_pressed("ui_down") or _is_arrow_key(event, KEY_DOWN):
		lane = 1; action = "down"
	elif event.is_action_pressed("up") or event.is_action_pressed("ui_up") or _is_arrow_key(event, KEY_UP):
		lane = 2; action = "up"
	elif event.is_action_pressed("right") or event.is_action_pressed("ui_right") or _is_arrow_key(event, KEY_RIGHT):
		lane = 3; action = "right"

	if lane == -1:
		return

	handle_lane_press(lane, action)

func handle_lane_press(lane_index: int, action_name: String) -> void:
	if arrows:
		var receptor = arrows.find_child(action_name)
		if receptor and receptor.has_method("play_click"):
			receptor.play_click()
	check_hit_for_lane(lane_index)

func check_hit_for_lane(lane_index: int) -> void:
	if not music_player or not music_player.playing:
		return

	var candidate_note: falling_arrow = null
	var min_dist: float = 99999.0

	for note_node in active_notes:
		if is_instance_valid(note_node) and note_node is falling_arrow:
			if note_node.note_info.get("lane", -1) == lane_index:
				var dist = abs(note_node.position.y - TARGET_Y)
				if dist < min_dist:
					min_dist = dist
					candidate_note = note_node

	if candidate_note and min_dist <= hit_tolerance_ok:
		var hit_rating := "OK"
		var score_add := 30

		if min_dist <= hit_tolerance_perfect:
			hit_rating = "PERFEITO!"
			score_add = 100
		elif min_dist <= hit_tolerance_good:
			hit_rating = "MUITO BOM!"
			score_add = 60

		misses_streak = 0  # resetar sequência de erros

		var note_val: float  = candidate_note.note_info.get("value", 1.0)
		var figure_name: String = candidate_note.note_info.get("name", "Nota")

		if control:
			control.update_score(score_add)
			control.update_last_state(hit_rating)
			control.add_note_to_compass(note_val, figure_name)
			_check_measures_for_challenge()

		active_notes.erase(candidate_note)
		var tw = create_tween()
		tw.parallel().tween_property(candidate_note, "scale", candidate_note.scale * 1.3, 0.1)
		tw.parallel().tween_property(candidate_note, "modulate:a", 0.0, 0.1)
		tw.tween_callback(candidate_note.queue_free)
	else:
		_register_miss()

# ─── SISTEMA DE DERROTA ───────────────────────────────────────────────────

func _register_miss() -> void:
	misses_streak += 1
	if control:
		control.reset_combo()
		control.update_last_state("ERROU!")

	if misses_streak >= misses_for_life_loss:
		misses_streak = 0
		_lose_life()

func _lose_life() -> void:
	lives -= 1
	_update_lives_display()

	if lives <= 0:
		lives = 0
		_trigger_game_over()
	else:
		# Animação de dano
		if control:
			control.update_last_state("💔 VIDA PERDIDA!")
		_flash_screen(Color("#FF6B6B"), 0.3)

func _update_lives_display() -> void:
	for i in range(_lives_labels.size()):
		var lbl = _lives_labels[i] as Label
		if lbl:
			if i < lives:
				lbl.add_theme_color_override("font_color", Color("#FF6B9D"))
				lbl.modulate = Color(1, 1, 1, 1)
			else:
				lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 0.5))
				lbl.text = "♡"

func _flash_screen(col: Color, duration: float) -> void:
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(col.r, col.g, col.b, 0.4)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_canvas.add_child(flash)
	var tw = create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, duration)
	tw.tween_callback(flash.queue_free)

func _trigger_game_over() -> void:
	if game_over_active:
		return
	game_over_active = true
	set_process(false)
	music_player.stop()

	_flash_screen(Color("#FF6B6B"), 0.6)
	await get_tree().create_timer(0.5).timeout

	if _game_over_panel:
		_game_over_panel.visible = true
		if _btn_game_over_retry:
			_btn_game_over_retry.call_deferred("grab_focus")
		# Atualiza dados do game over
		var title_lbl = _game_over_panel.get_meta("title_label") as Label
		var score_lbl = _game_over_panel.get_meta("score_label") as Label
		var comp_lbl  = _game_over_panel.get_meta("compass_label") as Label

		if game_won:
			if title_lbl: title_lbl.text = "★ VITÓRIA! ★"
			if title_lbl: title_lbl.add_theme_color_override("font_color", Color("#FFD166"))
		else:
			if title_lbl: title_lbl.text = "♩ FIM DE JOGO ♩"
			if title_lbl: title_lbl.add_theme_color_override("font_color", Color("#FF6B6B"))

		if control and score_lbl:
			score_lbl.text = "Pontuação Final: %d" % control.score
		if control and comp_lbl:
			comp_lbl.text = "Compassos: %d ★ | Dificuldade: %s" % [control.completed_compasses, GameManager.get_difficulty_name()]

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")

# ─── PAUSA ─────────────────────────────────────────────────────────────────

func _toggle_pause() -> void:
	if game_over_active:
		return
	paused = not paused
	if _pause_panel:
		_pause_panel.visible = paused
		if paused and _btn_pause_resume:
			_btn_pause_resume.call_deferred("grab_focus")
	if music_player:
		if paused:
			music_player.stream_paused = true
		else:
			music_player.stream_paused = false
	get_tree().paused = paused

func _on_resume_pressed() -> void:
	if paused:
		_toggle_pause()

func _on_config_keys_pressed() -> void:
	if _keybinding_instance and is_instance_valid(_keybinding_instance):
		return
	if _pause_panel:
		_pause_panel.visible = false
	var kb_canvas := CanvasLayer.new()
	kb_canvas.layer = 30
	kb_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(kb_canvas)

	var kb_menu = KEYBINDING_SCENE.instantiate()
	_keybinding_instance = kb_menu
	kb_canvas.add_child(kb_menu)

	kb_menu.closed.connect(func():
		_keybinding_instance = null
		kb_canvas.queue_free()
		if paused and not game_over_active and _pause_panel:
			_pause_panel.visible = true
			if _btn_pause_keys:
				_btn_pause_keys.call_deferred("grab_focus")
			elif _btn_pause_resume:
				_btn_pause_resume.call_deferred("grab_focus")
		setup_receptors()
	)

# ─── DESAFIO MATEMÁTICO ───────────────────────────────────────────────────

func _init_challenge_pool() -> void:
	_challenge_idx_pool.clear()
	for i in range(current_math_challenges.size()):
		_challenge_idx_pool.append(i)
	_challenge_idx_pool.shuffle()

func _check_measures_for_challenge() -> void:
	if math_challenge_active or challenges_spawned >= MAX_CHALLENGES_PER_GAME:
		return
	if control and control.has_method("get_completed_compasses"):
		var completed = control.get_completed_compasses()
		if completed > 0 and completed % MEASURES_PER_CHALLENGE == 0 and completed != last_challenge_measure:
			last_challenge_measure = completed
			_spawn_math_challenge()

func _spawn_math_challenge() -> void:
	if challenges_spawned >= MAX_CHALLENGES_PER_GAME:
		return

	if _challenge_idx_pool.is_empty():
		_init_challenge_pool()

	var idx = _challenge_idx_pool.pop_back()
	var challenge = current_math_challenges[idx]

	challenges_spawned += 1
	math_challenge_active = true
	_challenge_resolving = false
	errors_in_current_challenge = 0
	math_challenge_correct_lane = challenge["lane"]
	math_challenge_timer = math_challenge_duration

	# CONGELA A MÚSICA E O FLUXO DE NOTAS
	if music_player:
		music_player.stream_paused = true

	if _math_popup_title:
		_math_popup_title.text = "⚡ DESAFIO MATEMÁTICO (%d/%d) [%04.1fs] ⚡" % [challenges_spawned, MAX_CHALLENGES_PER_GAME, math_challenge_duration]
		_math_popup_title.add_theme_color_override("font_color", Color("#FFD166"))
	if _math_popup_label:
		_math_popup_label.text = challenge["eq"]
	if _math_popup_hint:
		_math_popup_hint.text = challenge.get("prompt", "Escolha a nota correspondente:")

	_update_challenge_buttons_labels()

	if _math_popup:
		_math_popup.modulate.a = 1.0
		_math_popup.visible = true
	if _math_timer_bar:
		_math_timer_bar.value = 1.0

func _resolve_math_challenge(pressed_lane: int) -> void:
	if not math_challenge_active or _challenge_resolving:
		return

	if pressed_lane == math_challenge_correct_lane:
		# Correto!
		_challenge_resolving = true
		if control:
			control.update_score(250)
			control.update_last_state("✓ RESPOSTA CORRETA! +250 🎓")
		_flash_screen(Color("#06D6A0"), 0.25)
		_highlight_challenge_button(pressed_lane, true)
		if _math_popup_title:
			_math_popup_title.text = "★ RESPOSTA CORRETA! +250 ★"
			_math_popup_title.add_theme_color_override("font_color", Color("#06D6A0"))
		await get_tree().create_timer(0.35).timeout
		_end_math_challenge()
	else:
		# Errado — reduz o tempo restante proporcionalmente à dificuldade!
		# A cada erro consecutivo no mesmo desafio, a penalidade aumenta mais ainda.
		errors_in_current_challenge += 1
		var penalty = math_error_penalty + (float(errors_in_current_challenge - 1) * 0.5)
		math_challenge_timer = max(0.0, math_challenge_timer - penalty)

		if control:
			control.update_last_state("✗ Errou! -%0.1fs de tempo!" % penalty)

		_flash_screen(Color("#FF6B6B"), 0.25)
		_highlight_challenge_button(pressed_lane, false)

		if _math_popup_title:
			_math_popup_title.text = "⚡ ERRO! -%0.1fs! [%04.1fs] ⚡" % [penalty, max(0.0, math_challenge_timer)]
			_math_popup_title.add_theme_color_override("font_color", Color("#FF6B6B"))

		if _math_timer_bar:
			_math_timer_bar.value = clampf(math_challenge_timer / math_challenge_duration, 0.0, 1.0)

		if math_challenge_timer <= 0.0:
			if control:
				control.update_last_state("⏱ Tempo esgotado!")
			_end_math_challenge()

func _end_math_challenge() -> void:
	math_challenge_active = false
	_challenge_resolving = false
	math_challenge_correct_lane = -1

	# DESCONGELA A MÚSICA E O FLUXO DE NOTAS
	if music_player:
		music_player.stream_paused = false

	if _math_popup:
		var tw = create_tween()
		tw.tween_property(_math_popup, "modulate:a", 0.0, 0.25)
		tw.tween_callback(func(): _math_popup.visible = false; _math_popup.modulate.a = 1.0)

# ─── SPAWN E PROCESSAMENTO DE NOTAS ──────────────────────────────────────

func spawn_falling_note(note_data: Dictionary) -> void:
	var arrow_type = note_data.get("arrow", Music.Arrow.LEFT)
	var info = Music.get_note_info(arrow_type)
	var lane = info.get("lane", 0)
	var target_time = note_data.get("time", 0.0)

	var start_pos = Vector2(lane_x[lane], SPAWN_Y)
	var end_pos   = Vector2(lane_x[lane], TARGET_Y)

	var new_arrow = FALLING_ARROW.instantiate() as falling_arrow
	falling_arrows.add_child(new_arrow)
	new_arrow.position = start_pos
	new_arrow.setup_note(info, target_time, start_pos, end_pos)
	active_notes.append(new_arrow)

func _process(delta: float) -> void:
	if paused or game_over_active:
		return
	if not music_player:
		return

	# Timer do desafio matemático E CONGELAMENTO DAS SETINHAS:
	if math_challenge_active:
		math_challenge_timer -= delta
		if _math_timer_bar:
			_math_timer_bar.value = clampf(math_challenge_timer / math_challenge_duration, 0.0, 1.0)
		if _math_popup_title and not _challenge_resolving:
			_math_popup_title.text = "⚡ DESAFIO MATEMÁTICO (%d/%d) [%04.1fs] ⚡" % [challenges_spawned, MAX_CHALLENGES_PER_GAME, max(0.0, math_challenge_timer)]
		if math_challenge_timer <= 0.0:
			if control:
				control.update_last_state("⏱ Tempo esgotado!")
			_end_math_challenge()
		return  # Congela a descida das notas e o áudio durante o desafio

	if not music_player.playing:
		return

	var current_time = music_player.get_playback_position()

	# Metrônomo BPM sincronizado com áudio (sem drift)
	var current_beat = int(floor(current_time / beat_interval))
	if current_beat > last_beat_idx:
		last_beat_idx = current_beat
		trigger_bpm_pulse(current_beat)

	# Spawna notas da fila com antecipação ajustada pela dificuldade (fall_time)
	while current_note_idx < notes.size():
		var note = notes[current_note_idx]
		var spawn_time = note["time"] - fall_time

		if current_time >= spawn_time:
			spawn_falling_note(note)
			current_note_idx += 1
		else:
			break

	# Atualiza posição das notas na pauta
	var to_remove: Array = []
	for note_node in active_notes:
		if is_instance_valid(note_node):
			var prog = 1.0 - (note_node.target_time - current_time) / fall_time
			var current_y = lerp(SPAWN_Y, TARGET_Y, prog)
			note_node.position = Vector2(note_node.initial_pos.x, current_y)

			# Miss automático se passar da linha alvo (prog > 1.15)
			if prog > 1.15:
				to_remove.append(note_node)
		else:
			to_remove.append(note_node)

	for missed in to_remove:
		active_notes.erase(missed)
		if is_instance_valid(missed):
			missed.queue_free()
		_register_miss()

	# Vitória: fim da música
	if current_note_idx >= notes.size() and active_notes.is_empty():
		set_process(false)
		game_won = true
		await get_tree().create_timer(1.5).timeout
		if lives > 0:
			GameManager.save_game_completed()
			get_tree().change_scene_to_file("res://scenes/cutscenes/epilogo.tscn")
		else:
			_trigger_game_over()

func trigger_bpm_pulse(beat_index: int) -> void:
	var beat_in_measure = (beat_index % 4) + 1
	if control and control.has_method("on_bpm_beat"):
		control.on_bpm_beat(beat_in_measure)
