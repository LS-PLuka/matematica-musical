extends Control
## Menu de configuração de teclas do jogo de ritmo.
## Constrói toda a interface programaticamente e salva os bindings
## em user://keybindings.cfg usando InputMap em tempo de execução.
##
## NAVEGAÇÃO:
##   Tab / ↑↓    → navegar entre botões
##   Enter/Space → ativar botão em foco
##   ESC         → cancelar captura ou fechar o menu

const CONFIG_PATH := "user://keybindings.cfg"

# Ações mapeáveis e seus metadados
const ACTIONS := [
	{"action": "left",  "label": "Semibreve  (4t)", "color": Color("#FF6B9D"), "icon": "←"},
	{"action": "down",  "label": "Mínima     (2t)", "color": Color("#5CE1E6"), "icon": "↓"},
	{"action": "up",    "label": "Semínima   (1t)", "color": Color("#FFD166"), "icon": "↑"},
	{"action": "right", "label": "Colcheia   (½t)", "color": Color("#06D6A0"), "icon": "→"},
]

var _font: FontFile
var _awaiting_input_for: String = ""  # action aguardando nova tecla
var _key_buttons: Dictionary = {}     # action -> Button
var _current_keys: Dictionary = {}    # action -> String (nome da tecla)
var _status_label: Label
var _nav_hint_label: Label

# Estilos reutilizáveis para os botões de tecla
var _styles: Dictionary = {}  # action -> {"normal", "hover", "focus", "capture"}

# Lista de todos os botões navegáveis (ordem de foco)
var _nav_order: Array[Button] = []
var _btn_save: Button
var _btn_reset: Button
var _btn_close: Button

signal closed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = load("res://assets/fonts/joystix monospace.otf")
	_load_current_bindings()
	_build_ui()
	_setup_focus_chain()
	call_deferred("_grab_initial_focus")

# ─── CARREGAMENTO DE BINDINGS ─────────────────────────────────────────────

func _load_current_bindings() -> void:
	for action_info in ACTIONS:
		var action: String = action_info["action"]
		_current_keys[action] = _get_key_name_for_action(action)

func _get_key_name_for_action(action: String) -> String:
	var events = InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			var keycode = (ev as InputEventKey).physical_keycode
			return OS.get_keycode_string(keycode)
	return "?"

# ─── CONSTRUÇÃO DA INTERFACE ──────────────────────────────────────────────

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Fundo escurecido com clique para fechar
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.78)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Painel central
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -310.0
	panel.offset_top    = -260.0
	panel.offset_right  =  310.0
	panel.offset_bottom =  270.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.10, 0.07, 0.98)
	panel_style.border_color = Color("#FFD166")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  24.0
	vbox.offset_top    =  20.0
	vbox.offset_right  = -24.0
	vbox.offset_bottom = -20.0
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# ── Cabeçalho ──────────────────────────────────────────
	var title = Label.new()
	title.text = "⌨  CONFIGURAR TECLAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#FFD166"))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title)

	# Dica de navegação (pequena, discreta)
	_nav_hint_label = Label.new()
	_nav_hint_label.text = "Tab/↑↓ navegar  ·  Enter selecionar  ·  ESC fechar"
	_nav_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nav_hint_label.add_theme_font_override("font", _font)
	_nav_hint_label.add_theme_font_size_override("font_size", 9)
	_nav_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.8))
	vbox.add_child(_nav_hint_label)

	vbox.add_child(HSeparator.new())

	# ── Linhas de ação ─────────────────────────────────────
	for action_info in ACTIONS:
		vbox.add_child(_build_action_row(action_info))

	vbox.add_child(HSeparator.new())

	# ── Status ─────────────────────────────────────────────
	_status_label = Label.new()
	_status_label.text = "Selecione uma tecla para remapear"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.custom_minimum_size = Vector2(0, 32)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_status_label.add_theme_font_override("font", _font)
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.9))
	vbox.add_child(_status_label)

	vbox.add_child(HSeparator.new())

	# ── Botões de ação ─────────────────────────────────────
	var hbox_btns = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox_btns)

	_btn_save  = _make_btn("✔  Salvar",  Color("#06D6A0"))
	_btn_reset = _make_btn("↺  Padrão",  Color("#5CE1E6"))
	_btn_close = _make_btn("✖  Fechar",  Color("#FF6B6B"))

	_btn_save.pressed.connect(_on_save_pressed)
	_btn_reset.pressed.connect(_on_reset_pressed)
	_btn_close.pressed.connect(_on_close_pressed)

	hbox_btns.add_child(_btn_save)
	hbox_btns.add_child(_btn_reset)
	hbox_btns.add_child(_btn_close)

# ─── LINHA DE AÇÃO ────────────────────────────────────────────────────────

func _build_action_row(action_info: Dictionary) -> HBoxContainer:
	var action: String = action_info["action"]
	var col: Color     = action_info["color"]

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# Ícone
	var icon_lbl = Label.new()
	icon_lbl.text = action_info["icon"]
	icon_lbl.custom_minimum_size = Vector2(28, 0)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_override("font", _font)
	icon_lbl.add_theme_font_size_override("font_size", 20)
	icon_lbl.add_theme_color_override("font_color", col)
	row.add_child(icon_lbl)

	# Nome da nota
	var name_lbl = Label.new()
	name_lbl.text = action_info["label"]
	name_lbl.custom_minimum_size = Vector2(160, 0)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_override("font", _font)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", col)
	row.add_child(name_lbl)

	# Botão da tecla — 3 estados visuais: normal, hover/focus, capturing
	var style_n = StyleBoxFlat.new()
	style_n.bg_color = Color(0.07, 0.15, 0.11, 0.9)
	style_n.border_color = col
	style_n.set_border_width_all(2)
	style_n.set_corner_radius_all(5)
	style_n.set_content_margin_all(8)

	var style_h = StyleBoxFlat.new()
	style_h.bg_color = Color(col.r * 0.22, col.g * 0.22, col.b * 0.22, 0.95)
	style_h.border_color = Color(1, 1, 1, 1)
	style_h.set_border_width_all(3)
	style_h.set_corner_radius_all(5)
	style_h.set_content_margin_all(8)

	# "Focus" com borda brilhante da cor da nota
	var style_f = StyleBoxFlat.new()
	style_f.bg_color = Color(col.r * 0.18, col.g * 0.18, col.b * 0.18, 0.95)
	style_f.border_color = col.lightened(0.35)
	style_f.set_border_width_all(3)
	style_f.set_corner_radius_all(5)
	style_f.set_content_margin_all(8)

	# "Capturing" — amarelo pulsante (aplicado ao texto via update_key_button_state)
	var style_c = StyleBoxFlat.new()
	style_c.bg_color = Color(0.3, 0.25, 0.0, 0.95)
	style_c.border_color = Color("#FFD166")
	style_c.set_border_width_all(3)
	style_c.set_corner_radius_all(5)
	style_c.set_content_margin_all(8)

	_styles[action] = {
		"normal":    style_n,
		"hover":     style_h,
		"focus":     style_f,
		"capturing": style_c
	}

	var key_btn = Button.new()
	key_btn.text = "[ %s ]" % _current_keys[action]
	key_btn.custom_minimum_size = Vector2(130, 36)
	key_btn.add_theme_font_override("font", _font)
	key_btn.add_theme_font_size_override("font_size", 13)
	key_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	key_btn.add_theme_stylebox_override("normal",  style_n)
	key_btn.add_theme_stylebox_override("hover",   style_h)
	key_btn.add_theme_stylebox_override("pressed", style_h)
	key_btn.add_theme_stylebox_override("focus",   style_f)

	key_btn.pressed.connect(_on_key_button_pressed.bind(action))
	_key_buttons[action] = key_btn
	row.add_child(key_btn)

	return row

func _make_btn(txt: String, col: Color) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))

	var sn = StyleBoxFlat.new()
	sn.bg_color = Color(0.06, 0.12, 0.09, 0.9)
	sn.border_color = col
	sn.set_border_width_all(2)
	sn.set_corner_radius_all(5)
	sn.set_content_margin_all(10)

	var sh = StyleBoxFlat.new()
	sh.bg_color = Color(col.r * 0.2, col.g * 0.2, col.b * 0.2, 0.95)
	sh.border_color = Color(1, 1, 1, 0.9)
	sh.set_border_width_all(2)
	sh.set_corner_radius_all(5)
	sh.set_content_margin_all(10)

	# Foco: borda brilhante da cor do botão
	var sf = StyleBoxFlat.new()
	sf.bg_color = Color(col.r * 0.18, col.g * 0.18, col.b * 0.18, 0.95)
	sf.border_color = col.lightened(0.35)
	sf.set_border_width_all(3)
	sf.set_corner_radius_all(5)
	sf.set_content_margin_all(10)

	btn.add_theme_stylebox_override("normal",  sn)
	btn.add_theme_stylebox_override("hover",   sh)
	btn.add_theme_stylebox_override("pressed", sh)
	btn.add_theme_stylebox_override("focus",   sf)
	return btn

# ─── CADEIA DE FOCO ───────────────────────────────────────────────────────

func _setup_focus_chain() -> void:
	# Ordem de navegação: teclas das 4 ações → Salvar → Padrão → Fechar
	_nav_order.clear()
	for action_info in ACTIONS:
		var action: String = action_info["action"]
		if _key_buttons.has(action):
			_nav_order.append(_key_buttons[action] as Button)
	_nav_order.append(_btn_save)
	_nav_order.append(_btn_reset)
	_nav_order.append(_btn_close)

	# Define focus_next e focus_previous em loop
	for i in range(_nav_order.size()):
		var btn   = _nav_order[i]
		var prev  = _nav_order[(i - 1 + _nav_order.size()) % _nav_order.size()]
		var nxt   = _nav_order[(i + 1) % _nav_order.size()]
		btn.focus_neighbor_top    = btn.get_path_to(prev)
		btn.focus_neighbor_bottom = btn.get_path_to(nxt)
		btn.focus_neighbor_left   = btn.get_path_to(prev)
		btn.focus_neighbor_right  = btn.get_path_to(nxt)
		btn.focus_previous        = btn.get_path_to(prev)
		btn.focus_next            = btn.get_path_to(nxt)

func _grab_initial_focus() -> void:
	if not _nav_order.is_empty():
		_nav_order[0].grab_focus()

# ─── INPUT ────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if not event is InputEventKey:
		return

	var key_event = event as InputEventKey
	var keycode   = key_event.physical_keycode

	# ESC: cancela captura em andamento OU fecha o menu
	if keycode == KEY_ESCAPE:
		if not _awaiting_input_for.is_empty():
			_cancel_capture()
		else:
			_on_close_pressed()
		get_viewport().set_input_as_handled()
		return

	# Se aguardando tecla, captura qualquer outra tecla
	if not _awaiting_input_for.is_empty():
		_finish_capture(key_event)
		get_viewport().set_input_as_handled()
		return

	# Atalhos de teclado globais quando nenhuma captura está ativa
	match keycode:
		KEY_ENTER, KEY_KP_ENTER:
			# "Enter" no botão em foco já é tratado pelo Godot — não precisamos fazer nada
			pass
		KEY_S:
			if key_event.ctrl_pressed:
				_on_save_pressed()
				get_viewport().set_input_as_handled()
		_:
			pass

# ─── CAPTURA DE TECLA ─────────────────────────────────────────────────────

func _on_key_button_pressed(action: String) -> void:
	# Se já estava capturando outra, cancela
	if not _awaiting_input_for.is_empty() and _awaiting_input_for != action:
		_cancel_capture()

	_awaiting_input_for = action
	_set_key_btn_capturing(action, true)
	_set_status("⚡ Pressione a nova tecla para  \"%s\"  [ESC = cancelar]" % action, Color("#FFD166"))
	_update_nav_hint("Pressione qualquer tecla  ·  ESC cancela")

func _finish_capture(key_event: InputEventKey) -> void:
	var keycode  = key_event.physical_keycode
	var key_name = OS.get_keycode_string(keycode)
	var action   = _awaiting_input_for

	_awaiting_input_for = ""
	_set_key_btn_capturing(action, false)

	# Verifica conflito com outras ações
	for other_info in ACTIONS:
		var other_action: String = other_info["action"]
		if other_action != action and _current_keys[other_action] == key_name:
			_set_status("⚠  \"%s\" já usada por outra ação! Tente outra tecla." % key_name,
				Color("#FF6B6B"))
			# Restaura botão sem alterar a tecla
			if _key_buttons.has(action):
				(_key_buttons[action] as Button).text = "[ %s ]" % _current_keys[action]
			_restore_nav_hint()
			return

	# Aplica a nova tecla
	_current_keys[action] = key_name
	if _key_buttons.has(action):
		(_key_buttons[action] as Button).text = "[ %s ]" % key_name
	_set_status("✔  \"%s\" → \"%s\"   (Ctrl+S ou Salvar para confirmar)" % [action, key_name],
		Color("#06D6A0"))
	_restore_nav_hint()

	# Devolve foco ao botão mapeado
	if _key_buttons.has(action):
		(_key_buttons[action] as Button).grab_focus()

func _cancel_capture() -> void:
	var action = _awaiting_input_for
	_awaiting_input_for = ""
	_set_key_btn_capturing(action, false)
	if _key_buttons.has(action):
		(_key_buttons[action] as Button).text = "[ %s ]" % _current_keys[action]
		(_key_buttons[action] as Button).grab_focus()
	_set_status("Remapeamento cancelado.", Color(0.7, 0.7, 0.7, 0.9))
	_restore_nav_hint()

func _set_key_btn_capturing(action: String, capturing: bool) -> void:
	if not _key_buttons.has(action):
		return
	var btn = _key_buttons[action] as Button
	if not _styles.has(action):
		return
	var st = _styles[action]
	if capturing:
		btn.text = "[ pressione... ]"
		btn.add_theme_stylebox_override("normal",  st["capturing"])
		btn.add_theme_stylebox_override("hover",   st["capturing"])
		btn.add_theme_stylebox_override("focus",   st["capturing"])
		btn.add_theme_stylebox_override("pressed", st["capturing"])
		btn.add_theme_color_override("font_color", Color("#FFD166"))
	else:
		btn.add_theme_stylebox_override("normal",  st["normal"])
		btn.add_theme_stylebox_override("hover",   st["hover"])
		btn.add_theme_stylebox_override("focus",   st["focus"])
		btn.add_theme_stylebox_override("pressed", st["hover"])
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))

# ─── SALVAR / RESETAR / FECHAR ─────────────────────────────────────────────

func _on_save_pressed() -> void:
	if not _awaiting_input_for.is_empty():
		_cancel_capture()
	_apply_keybindings()
	_save_to_file()
	_set_status("✔  Teclas salvas com sucesso!", Color("#06D6A0"))

func _apply_keybindings() -> void:
	for action_info in ACTIONS:
		var action: String   = action_info["action"]
		var key_name: String = _current_keys[action]

		var old_events = InputMap.action_get_events(action)
		for ev in old_events:
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)

		var new_event = InputEventKey.new()
		new_event.physical_keycode = OS.find_keycode_from_string(key_name)
		InputMap.action_add_event(action, new_event)

func _save_to_file() -> void:
	var cfg = ConfigFile.new()
	for action_info in ACTIONS:
		var action: String = action_info["action"]
		cfg.set_value("rhythm_keys", action, _current_keys[action])
	cfg.save(CONFIG_PATH)

func _on_reset_pressed() -> void:
	if not _awaiting_input_for.is_empty():
		_cancel_capture()
	InputMap.load_from_project_settings()
	_load_current_bindings()
	for action_info in ACTIONS:
		var action: String = action_info["action"]
		if _key_buttons.has(action):
			(_key_buttons[action] as Button).text = "[ %s ]" % _current_keys[action]
	_set_status("↺  Teclas padrão restauradas.", Color("#5CE1E6"))
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(CONFIG_PATH)

func _on_close_pressed() -> void:
	if not _awaiting_input_for.is_empty():
		_cancel_capture()
		return  # primeiro ESC cancela captura, segundo fecha
	closed.emit()
	queue_free()

# ─── HELPERS DE STATUS / HINT ─────────────────────────────────────────────

func _set_status(msg: String, col: Color) -> void:
	if not _status_label:
		return
	_status_label.text = msg
	_status_label.add_theme_color_override("font_color", col)
	# Animação suave de aparecimento
	_status_label.modulate = Color(1.3, 1.3, 1.3, 1)
	var tw = create_tween()
	tw.tween_property(_status_label, "modulate", Color(1, 1, 1, 1), 0.25)

func _update_nav_hint(msg: String) -> void:
	if _nav_hint_label:
		_nav_hint_label.text = msg

func _restore_nav_hint() -> void:
	_update_nav_hint("Tab/↑↓ navegar  ·  Enter selecionar  ·  ESC fechar")
