extends Control
## Menu de configuração de teclas do jogo de ritmo.
## Constrói toda a interface programaticamente e salva os bindings
## em user://keybindings.cfg usando InputMap em tempo de execução.

const CONFIG_PATH := "user://keybindings.cfg"

# Ações mapeáveis e seus metadados
const ACTIONS := [
	{"action": "left",  "label": "Semibreve  (4t)", "color": Color("#FF6B9D"), "icon": "←"},
	{"action": "down",  "label": "Mínima     (2t)", "color": Color("#5CE1E6"), "icon": "↓"},
	{"action": "up",    "label": "Semínima   (1t)", "color": Color("#FFD166"), "icon": "↑"},
	{"action": "right", "label": "Colcheia   (½t)", "color": Color("#06D6A0"), "icon": "→"},
]

var _font: FontFile
var _awaiting_input_for: String = ""   # qual action está aguardando tecla
var _key_buttons: Dictionary = {}      # action -> Button
var _current_keys: Dictionary = {}     # action -> String (nome da tecla)
var _status_label: Label

signal closed

func _ready() -> void:
	_font = load("res://assets/fonts/joystix monospace.otf")
	_load_current_bindings()
	_build_ui()

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

	# Fundo escurecido
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.75)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Painel central
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -300.0
	panel.offset_top    = -240.0
	panel.offset_right  =  300.0
	panel.offset_bottom =  260.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.10, 0.07, 0.97)
	panel_style.border_color = Color("#FFD166")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  20.0
	vbox.offset_top    =  20.0
	vbox.offset_right  = -20.0
	vbox.offset_bottom = -20.0
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Título
	var title = Label.new()
	title.text = "⌨  CONFIGURAR TECLAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#FFD166"))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title)

	var sep1 = HSeparator.new()
	vbox.add_child(sep1)

	# Uma linha por ação
	for action_info in ACTIONS:
		vbox.add_child(_build_action_row(action_info))

	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Status label (instrução ao usuário)
	_status_label = Label.new()
	_status_label.text = "Clique em uma tecla para remapear"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_status_label.add_theme_font_override("font", _font)
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.9))
	vbox.add_child(_status_label)

	var sep3 = HSeparator.new()
	vbox.add_child(sep3)

	# Botões de ação
	var hbox_btns = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox_btns)

	var btn_save = _make_btn("✔  Salvar", Color("#06D6A0"))
	btn_save.pressed.connect(_on_save_pressed)
	hbox_btns.add_child(btn_save)

	var btn_reset = _make_btn("↺  Padrão", Color("#5CE1E6"))
	btn_reset.pressed.connect(_on_reset_pressed)
	hbox_btns.add_child(btn_reset)

	var btn_close = _make_btn("✖  Fechar", Color("#FF6B6B"))
	btn_close.pressed.connect(_on_close_pressed)
	hbox_btns.add_child(btn_close)

func _build_action_row(action_info: Dictionary) -> HBoxContainer:
	var action: String = action_info["action"]
	var col: Color     = action_info["color"]

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	# Ícone da direção
	var icon_lbl = Label.new()
	icon_lbl.text = action_info["icon"]
	icon_lbl.custom_minimum_size = Vector2(30, 0)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_override("font", _font)
	icon_lbl.add_theme_font_size_override("font_size", 18)
	icon_lbl.add_theme_color_override("font_color", col)
	row.add_child(icon_lbl)

	# Nome da nota
	var name_lbl = Label.new()
	name_lbl.text = action_info["label"]
	name_lbl.custom_minimum_size = Vector2(170, 0)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_override("font", _font)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", col)
	row.add_child(name_lbl)

	# Botão com a tecla atual
	var key_btn = Button.new()
	key_btn.text = "[ %s ]" % _current_keys[action]
	key_btn.custom_minimum_size = Vector2(120, 34)
	key_btn.add_theme_font_override("font", _font)
	key_btn.add_theme_font_size_override("font_size", 13)
	key_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))

	var style_n = StyleBoxFlat.new()
	style_n.bg_color = Color(0.07, 0.15, 0.11, 0.9)
	style_n.border_color = col
	style_n.set_border_width_all(2)
	style_n.set_corner_radius_all(4)
	style_n.set_content_margin_all(6)
	var style_h = StyleBoxFlat.new()
	style_h.bg_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 0.95)
	style_h.border_color = Color(1, 1, 1, 0.9)
	style_h.set_border_width_all(2)
	style_h.set_corner_radius_all(4)
	style_h.set_content_margin_all(6)
	key_btn.add_theme_stylebox_override("normal", style_n)
	key_btn.add_theme_stylebox_override("hover",  style_h)
	key_btn.add_theme_stylebox_override("pressed", style_h)
	key_btn.add_theme_stylebox_override("focus",  style_n)

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
	sn.set_content_margin_all(9)
	var sh = StyleBoxFlat.new()
	sh.bg_color = Color(col.r * 0.2, col.g * 0.2, col.b * 0.2, 0.95)
	sh.border_color = Color(1, 1, 1, 0.9)
	sh.set_border_width_all(2)
	sh.set_corner_radius_all(5)
	sh.set_content_margin_all(9)
	btn.add_theme_stylebox_override("normal", sn)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", sh)
	btn.add_theme_stylebox_override("focus", sn)
	return btn

# ─── LÓGICA DE REMAPEAMENTO ────────────────────────────────────────────────

func _on_key_button_pressed(action: String) -> void:
	_awaiting_input_for = action
	if _key_buttons.has(action):
		(_key_buttons[action] as Button).text = "[ pressione... ]"
	if _status_label:
		_status_label.text = "Pressione qualquer tecla para \"%s\"..." % action

func _input(event: InputEvent) -> void:
	if _awaiting_input_for.is_empty():
		return
	if not event.is_pressed() or event.is_echo():
		return
	if not event is InputEventKey:
		return

	var key_event = event as InputEventKey
	if key_event.physical_keycode == KEY_ESCAPE:
		# Cancela a captura
		var action = _awaiting_input_for
		_awaiting_input_for = ""
		if _key_buttons.has(action):
			(_key_buttons[action] as Button).text = "[ %s ]" % _current_keys[action]
		if _status_label:
			_status_label.text = "Remapeamento cancelado."
		get_viewport().set_input_as_handled()
		return

	var keycode = key_event.physical_keycode
	var key_name = OS.get_keycode_string(keycode)
	var action = _awaiting_input_for
	_awaiting_input_for = ""

	# Verifica conflito
	for other_info in ACTIONS:
		var other_action: String = other_info["action"]
		if other_action != action and _current_keys[other_action] == key_name:
			if _status_label:
				_status_label.text = "⚠ \"%s\" já está em uso por outra ação!" % key_name
			if _key_buttons.has(action):
				(_key_buttons[action] as Button).text = "[ %s ]" % _current_keys[action]
			get_viewport().set_input_as_handled()
			return

	_current_keys[action] = key_name
	if _key_buttons.has(action):
		(_key_buttons[action] as Button).text = "[ %s ]" % key_name
	if _status_label:
		_status_label.text = "✔ \"%s\" → \"%s\"  (Clique Salvar para confirmar)" % [action, key_name]

	get_viewport().set_input_as_handled()

# ─── SALVAR / RESETAR / FECHAR ─────────────────────────────────────────────

func _on_save_pressed() -> void:
	_apply_keybindings()
	_save_to_file()
	if _status_label:
		_status_label.text = "✔ Teclas salvas com sucesso!"

func _apply_keybindings() -> void:
	for action_info in ACTIONS:
		var action: String = action_info["action"]
		var key_name: String = _current_keys[action]

		# Limpa eventos de teclado existentes
		var old_events = InputMap.action_get_events(action)
		for ev in old_events:
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)

		# Adiciona novo evento
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
	InputMap.load_from_project_settings()
	_load_current_bindings()
	for action_info in ACTIONS:
		var action: String = action_info["action"]
		if _key_buttons.has(action):
			(_key_buttons[action] as Button).text = "[ %s ]" % _current_keys[action]
	if _status_label:
		_status_label.text = "↺ Teclas padrão restauradas."
	# Remove arquivo de config customizado
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(CONFIG_PATH)

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
