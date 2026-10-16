extends Node
## Gerenciador global do jogo. Carrega configurações persistentes (keybindings e save de progresso)
## ao iniciar, garantindo que as teclas customizadas e dificuldades desbloqueadas estejam sempre ativas.

const KEYBINDING_CONFIG_PATH := "user://keybindings.cfg"
const SAVE_CONFIG_PATH := "user://game_save.cfg"

# Ações de ritmo mapeáveis
const RHYTHM_ACTIONS := ["left", "down", "up", "right"]

const DEFAULT_ARROW_KEYS := {
	"left": KEY_LEFT,
	"down": KEY_DOWN,
	"up": KEY_UP,
	"right": KEY_RIGHT
}

enum Difficulty {
	FACIL = 0,
	NORMAL = 1,
	DIFICIL = 2,
	HARDCORE = 3
}

const DIFFICULTY_NAMES := {
	Difficulty.FACIL: "FÁCIL",
	Difficulty.NORMAL: "NORMAL",
	Difficulty.DIFICIL: "DIFÍCIL",
	Difficulty.HARDCORE: "HARDCORE"
}

const DIFFICULTY_COLORS := {
	Difficulty.FACIL: Color("#06D6A0"),    # Verde
	Difficulty.NORMAL: Color("#5CE1E6"),   # Ciano
	Difficulty.DIFICIL: Color("#FFD166"),  # Amarelo/Dourado
	Difficulty.HARDCORE: Color("#FF6B6B")  # Vermelho
}

const DIFFICULTY_DESCRIPTIONS := {
	Difficulty.FACIL: "Ritmo mais calmo, margem de acerto generosa e frações básicas.",
	Difficulty.NORMAL: "A experiência padrão e equilibrada de Matemática Musical.",
	Difficulty.DIFICIL: "Ritmo rápido, menos tolerância a erros e frações mistas.",
	Difficulty.HARDCORE: "Velocidade máxima, precisão milimétrica e expressões de compasso complexas!"
}

var is_game_completed: bool = false
var selected_difficulty: Difficulty = Difficulty.NORMAL

signal difficulty_changed(new_difficulty: Difficulty)
signal game_completed_unlocked()

func _ready() -> void:
	_load_keybindings()
	_load_save_data()

func _load_save_data() -> void:
	if not FileAccess.file_exists(SAVE_CONFIG_PATH):
		return
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_CONFIG_PATH) == OK:
		is_game_completed = cfg.get_value("progression", "game_completed", false)
		var diff_val = cfg.get_value("settings", "difficulty", int(Difficulty.NORMAL))
		selected_difficulty = clampi(diff_val, 0, 3) as Difficulty

func save_game_completed() -> void:
	var first_time = not is_game_completed
	is_game_completed = true
	var cfg = ConfigFile.new()
	if FileAccess.file_exists(SAVE_CONFIG_PATH):
		cfg.load(SAVE_CONFIG_PATH)
	cfg.set_value("progression", "game_completed", true)
	cfg.save(SAVE_CONFIG_PATH)
	if first_time:
		game_completed_unlocked.emit()

func set_difficulty(diff: Difficulty) -> void:
	selected_difficulty = diff
	var cfg = ConfigFile.new()
	if FileAccess.file_exists(SAVE_CONFIG_PATH):
		cfg.load(SAVE_CONFIG_PATH)
	cfg.set_value("settings", "difficulty", int(diff))
	cfg.save(SAVE_CONFIG_PATH)
	difficulty_changed.emit(diff)

func cycle_difficulty() -> Difficulty:
	var next_diff = ((int(selected_difficulty) + 1) % 4) as Difficulty
	set_difficulty(next_diff)
	return next_diff

func get_difficulty_name() -> String:
	return DIFFICULTY_NAMES.get(selected_difficulty, "NORMAL")

func get_difficulty_color() -> Color:
	return DIFFICULTY_COLORS.get(selected_difficulty, Color.WHITE)

func get_difficulty_description() -> String:
	return DIFFICULTY_DESCRIPTIONS.get(selected_difficulty, "")

const RHYTHM_TO_UI_ACTION := {
	"left": "ui_left",
	"down": "ui_down",
	"up": "ui_up",
	"right": "ui_right"
}

const DEFAULT_WASD_KEYS := {
	"left": KEY_A,
	"down": KEY_S,
	"up": KEY_W,
	"right": KEY_D
}

func _load_keybindings() -> void:
	if not FileAccess.file_exists(KEYBINDING_CONFIG_PATH):
		reset_keybindings_to_default()
		return

	var cfg = ConfigFile.new()
	if cfg.load(KEYBINDING_CONFIG_PATH) != OK:
		push_warning("GameManager: falha ao carregar keybindings.cfg")
		reset_keybindings_to_default()
		return

	var bindings: Dictionary = {}
	for action in RHYTHM_ACTIONS:
		var key_name: String = cfg.get_value("rhythm_keys", action, "")
		if not key_name.is_empty():
			bindings[action] = key_name

	apply_keybindings(bindings)

func apply_keybindings(bindings: Dictionary) -> void:
	for action in RHYTHM_ACTIONS:
		var key_name: String = bindings.get(action, "")
		var keycode: Key = OS.find_keycode_from_string(key_name) if not key_name.is_empty() else KEY_NONE

		# 1. Atualiza a ação de ritmo
		var old_events = InputMap.action_get_events(action)
		for ev in old_events:
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)

		# Tecla customizada primeiro (para ser a principal identificada)
		if keycode != KEY_NONE:
			var new_event = InputEventKey.new()
			new_event.physical_keycode = keycode
			new_event.keycode = keycode
			InputMap.action_add_event(action, new_event)

		var def_arrow: Key = DEFAULT_ARROW_KEYS.get(action, KEY_NONE)
		# Se a tecla customizada não for uma setinha, mantém a setinha correspondente ativa como secundária
		if def_arrow != KEY_NONE and keycode != def_arrow and not (keycode in DEFAULT_ARROW_KEYS.values()):
			var arrow_ev = InputEventKey.new()
			arrow_ev.physical_keycode = def_arrow
			arrow_ev.keycode = def_arrow
			InputMap.action_add_event(action, arrow_ev)

		# 2. Sincroniza a ação de navegação de UI correspondente (ui_left, ui_down, ui_up, ui_right)
		var ui_action: String = RHYTHM_TO_UI_ACTION.get(action, "")
		if not ui_action.is_empty():
			_sync_ui_action(ui_action, def_arrow, keycode)

func _sync_ui_action(ui_action: String, default_arrow: Key, custom_key: Key) -> void:
	if not InputMap.has_action(ui_action):
		InputMap.add_action(ui_action)

	# Remove eventos de teclado antigos da ação de UI
	var old_ui_events = InputMap.action_get_events(ui_action)
	for ev in old_ui_events:
		if ev is InputEventKey:
			InputMap.action_erase_event(ui_action, ev)

	# Adiciona a setinha padrão correspondente (sempre disponível na UI)
	if default_arrow != KEY_NONE:
		var arrow_ev = InputEventKey.new()
		arrow_ev.physical_keycode = default_arrow
		arrow_ev.keycode = default_arrow
		InputMap.action_add_event(ui_action, arrow_ev)

	# Adiciona a tecla direcional customizada para navegar a interface
	if custom_key != KEY_NONE and custom_key != default_arrow:
		var custom_ev = InputEventKey.new()
		custom_ev.physical_keycode = custom_key
		custom_ev.keycode = custom_key
		InputMap.action_add_event(ui_action, custom_ev)

func save_keybindings(bindings: Dictionary) -> void:
	apply_keybindings(bindings)
	var cfg = ConfigFile.new()
	for action in RHYTHM_ACTIONS:
		if bindings.has(action):
			cfg.set_value("rhythm_keys", action, bindings[action])
	cfg.save(KEYBINDING_CONFIG_PATH)

func reset_keybindings_to_default() -> void:
	InputMap.load_from_project_settings()
	for action in RHYTHM_ACTIONS:
		var def_arrow: Key = DEFAULT_ARROW_KEYS.get(action, KEY_NONE)
		var def_wasd: Key = DEFAULT_WASD_KEYS.get(action, KEY_NONE)
		var ui_action: String = RHYTHM_TO_UI_ACTION.get(action, "")

		_ensure_key_on_action(action, def_arrow)
		_ensure_key_on_action(action, def_wasd)

		if not ui_action.is_empty():
			_ensure_key_on_action(ui_action, def_arrow)
			_ensure_key_on_action(ui_action, def_wasd)

	if FileAccess.file_exists(KEYBINDING_CONFIG_PATH):
		DirAccess.remove_absolute(KEYBINDING_CONFIG_PATH)

func _ensure_key_on_action(action: String, keycode: Key) -> void:
	if keycode == KEY_NONE:
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var ik = ev as InputEventKey
			if ik.physical_keycode == keycode or ik.keycode == keycode:
				return
	var new_ev = InputEventKey.new()
	new_ev.physical_keycode = keycode
	new_ev.keycode = keycode
	InputMap.action_add_event(action, new_ev)

