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
const FALL_TIME: float = 3.2
const SPAWN_Y: float = 75.0
const TARGET_Y: float = 520.0

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
const MISSES_FOR_LIFE_LOSS: int = 4  # perde vida após 4 erros consecutivos
var game_over_active: bool = false
var game_won: bool = false
var paused: bool = false

# --- SISTEMA DE DESAFIO MATEMÁTICO ---
var math_challenge_active: bool = false
var math_challenge_correct_lane: int = -1
var math_challenge_timer: float = 0.0
const MATH_CHALLENGE_DURATION: float = 8.0
var measures_since_last_challenge: int = 0
const MEASURES_PER_CHALLENGE: int = 2

# Desafios matemáticos disponíveis (equação, lane correta)
const MATH_CHALLENGES := [
	{"eq": "½ + ½ = ?t  →  Toque a nota de 1 tempo!", "lane": 2, "answer_name": "Semínima (W/↑)"},
	{"eq": "4 ÷ 2 = ?t  →  Toque a nota de 2 tempos!", "lane": 1, "answer_name": "Mínima (S/↓)"},
	{"eq": "1 + 1 + 1 + 1 = ?t  →  Nota de 4 tempos!", "lane": 0, "answer_name": "Semibreve (A/←)"},
	{"eq": "1 ÷ 2 = ?t  →  Toque a nota de ½ tempo!", "lane": 3, "answer_name": "Colcheia (D/→)"},
	{"eq": "2 × 2 = ?t  →  Nota de 4 tempos!", "lane": 0, "answer_name": "Semibreve (A/←)"},
	{"eq": "3 - 1 = ?t  →  Nota de 2 tempos!", "lane": 1, "answer_name": "Mínima (S/↓)"},
	{"eq": "¼ + ¼ = ?t  →  Toque a nota de ½ tempo!", "lane": 3, "answer_name": "Colcheia (D/→)"},
	{"eq": "2 × ½ = ?t  →  Nota de 1 tempo!", "lane": 2, "answer_name": "Semínima (W/↑)"},
]
var _challenge_idx_pool: Array = []

# Overlays criados em código
var _overlay_canvas: CanvasLayer
var _game_over_panel: Control
var _pause_panel: Control
var _math_popup: Control
var _math_popup_label: Label
var _math_timer_bar: ProgressBar
var _lives_labels: Array = []
var _keybinding_instance: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	notes = music_system.musics[0]
	setup_receptors()
	music_player.play()
	_init_challenge_pool()
	_create_hud_overlays()

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
		{"name": "right", "lane": 3, "key": _get_action_key_name("right", "D"),  "arrow": "→", "fig": "Colcheia",  "val": "½t", "color": Color("#06D6A0"), "tex": "res://assets/sprites/ui/colcheia.png"}
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

	# Botão Menu Principal
	var btn_menu = _make_overlay_button("⌂  Menu Principal", Color("#FFD166"), font)
	vbox.add_child(btn_menu)
	btn_menu.pressed.connect(_on_menu_pressed)

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

	var btn_keys = _make_overlay_button("⌨  Configurar Teclas", Color("#A78BFA"), font)
	vbox.add_child(btn_keys)
	btn_keys.pressed.connect(_on_config_keys_pressed)

	var btn_retry = _make_overlay_button("↻  Reiniciar", Color("#5CE1E6"), font)
	vbox.add_child(btn_retry)
	btn_retry.pressed.connect(_on_retry_pressed)

	var btn_menu = _make_overlay_button("⌂  Menu Principal", Color("#FF6B6B"), font)
	vbox.add_child(btn_menu)
	btn_menu.pressed.connect(_on_menu_pressed)

func _create_math_popup() -> void:
	_math_popup = Control.new()
	_math_popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_math_popup.offset_left   = -340.0
	_math_popup.offset_top    =   20.0
	_math_popup.offset_right  =  340.0
	_math_popup.offset_bottom =  110.0
	_math_popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_math_popup.visible = false
	_overlay_canvas.add_child(_math_popup)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.12, 0.08, 0.92)
	style.border_color = Color("#FFD166")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", style)
	_math_popup.add_child(panel)

	var font = load("res://assets/fonts/joystix monospace.otf") as FontFile
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "⚡ DESAFIO MATEMÁTICO! ⚡"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", font)
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color("#FFD166"))
	vbox.add_child(title_lbl)

	_math_popup_label = Label.new()
	_math_popup_label.text = ""
	_math_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_math_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_math_popup_label.add_theme_font_override("font", font)
	_math_popup_label.add_theme_font_size_override("font_size", 13)
	_math_popup_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_math_popup_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_math_popup_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(_math_popup_label)

	_math_timer_bar = ProgressBar.new()
	_math_timer_bar.custom_minimum_size = Vector2(0, 6)
	_math_timer_bar.max_value = 1.0
	_math_timer_bar.value = 1.0
	_math_timer_bar.show_percentage = false
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	bar_bg.set_corner_radius_all(3)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color("#FFD166")
	bar_fill.set_corner_radius_all(3)
	_math_timer_bar.add_theme_stylebox_override("background", bar_bg)
	_math_timer_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(_math_timer_bar)

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
		return
	if paused:
		return
	if not music_player or not music_player.playing:
		return

	var lane := -1
	var action := ""
	if Input.is_action_just_pressed("left"):
		lane = 0; action = "left"
	elif Input.is_action_just_pressed("down"):
		lane = 1; action = "down"
	elif Input.is_action_just_pressed("up"):
		lane = 2; action = "up"
	elif Input.is_action_just_pressed("right"):
		lane = 3; action = "right"

	if lane == -1:
		return

	# Verifica desafio matemático
	if math_challenge_active:
		_resolve_math_challenge(lane)
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

	if candidate_note and min_dist <= 72.0:
		var hit_rating := "OK"
		var score_add := 30

		if min_dist <= 24.0:
			hit_rating = "PERFEITO!"
			score_add = 100
		elif min_dist <= 48.0:
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

	if misses_streak >= MISSES_FOR_LIFE_LOSS:
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
			comp_lbl.text = "Compassos Fechados: %d ★" % control.completed_compasses

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")

# ─── PAUSA ─────────────────────────────────────────────────────────────────

func _toggle_pause() -> void:
	if game_over_active:
		return
	paused = not paused
	if _pause_panel:
		_pause_panel.visible = paused
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
		setup_receptors()
	)

# ─── DESAFIO MATEMÁTICO ───────────────────────────────────────────────────

func _init_challenge_pool() -> void:
	_challenge_idx_pool.clear()
	for i in range(MATH_CHALLENGES.size()):
		_challenge_idx_pool.append(i)
	_challenge_idx_pool.shuffle()

func _check_measures_for_challenge() -> void:
	if math_challenge_active:
		return
	# O controle notifica sobre compassos fechados via update_last_state; verificamos diretamente
	if control and control.has_method("get_completed_compasses"):
		var completed = control.get_completed_compasses()
		if completed > 0 and completed % MEASURES_PER_CHALLENGE == 0 and not math_challenge_active:
			_spawn_math_challenge()

func _spawn_math_challenge() -> void:
	if _challenge_idx_pool.is_empty():
		_init_challenge_pool()

	var idx = _challenge_idx_pool.pop_back()
	var challenge = MATH_CHALLENGES[idx]

	math_challenge_active = true
	math_challenge_correct_lane = challenge["lane"]
	math_challenge_timer = MATH_CHALLENGE_DURATION

	if _math_popup_label:
		_math_popup_label.text = challenge["eq"]
	if _math_popup:
		_math_popup.visible = true
	if _math_timer_bar:
		_math_timer_bar.value = 1.0

func _resolve_math_challenge(pressed_lane: int) -> void:
	if not math_challenge_active:
		return

	if pressed_lane == math_challenge_correct_lane:
		# Correto!
		if control:
			control.update_score(150)
			control.update_last_state("✓ RESPOSTA CORRETA! +150 🎓")
		_end_math_challenge()
		_flash_screen(Color("#06D6A0"), 0.25)
	else:
		# Errado — não perde vida, mas avisa
		if control:
			control.update_last_state("✗ Pense novamente...")

func _end_math_challenge() -> void:
	math_challenge_active = false
	math_challenge_correct_lane = -1
	if _math_popup:
		var tw = create_tween()
		tw.tween_property(_math_popup, "modulate:a", 0.0, 0.3)
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
	if not music_player or not music_player.playing:
		return

	var current_time = music_player.get_playback_position()

	# Metrônomo BPM sincronizado com áudio (sem drift)
	var current_beat = int(floor(current_time / beat_interval))
	if current_beat > last_beat_idx:
		last_beat_idx = current_beat
		trigger_bpm_pulse(current_beat)

	# Spawna notas da fila com antecipação suave (FALL_TIME = 3.2s)
	while current_note_idx < notes.size():
		var note = notes[current_note_idx]
		var spawn_time = note["time"] - FALL_TIME

		if current_time >= spawn_time:
			spawn_falling_note(note)
			current_note_idx += 1
		else:
			break

	# Atualiza posição das notas na pauta
	var to_remove: Array = []
	for note_node in active_notes:
		if is_instance_valid(note_node):
			var prog = 1.0 - (note_node.target_time - current_time) / FALL_TIME
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

	# Timer do desafio matemático
	if math_challenge_active:
		math_challenge_timer -= delta
		if _math_timer_bar:
			_math_timer_bar.value = math_challenge_timer / MATH_CHALLENGE_DURATION
		if math_challenge_timer <= 0.0:
			if control:
				control.update_last_state("⏱ Tempo esgotado!")
			_end_math_challenge()

	# Vitória: fim da música
	if current_note_idx >= notes.size() and active_notes.is_empty():
		set_process(false)
		game_won = true
		await get_tree().create_timer(1.5).timeout
		if lives > 0:
			get_tree().change_scene_to_file("res://scenes/cutscenes/epilogo.tscn")
		else:
			_trigger_game_over()

func trigger_bpm_pulse(beat_index: int) -> void:
	var beat_in_measure = (beat_index % 4) + 1
	if control and control.has_method("on_bpm_beat"):
		control.on_bpm_beat(beat_in_measure)
