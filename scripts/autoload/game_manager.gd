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

func _load_keybindings() -> void:
	if not FileAccess.file_exists(KEYBINDING_CONFIG_PATH):
		_ensure_arrow_keys_registered()
		return  # usa bindings padrão do projeto

	var cfg = ConfigFile.new()
	if cfg.load(KEYBINDING_CONFIG_PATH) != OK:
		push_warning("GameManager: falha ao carregar keybindings.cfg")
		_ensure_arrow_keys_registered()
		return

	for action in RHYTHM_ACTIONS:
		var key_name: String = cfg.get_value("rhythm_keys", action, "")
		var keycode: Key = OS.find_keycode_from_string(key_name) if not key_name.is_empty() else KEY_NONE

		# Remove eventos de teclado antigos
		var old_events = InputMap.action_get_events(action)
		for ev in old_events:
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)

		# Registra a tecla customizada
		if keycode != KEY_NONE:
			var new_event = InputEventKey.new()
			new_event.physical_keycode = keycode
			InputMap.action_add_event(action, new_event)

		# Garante que a setinha padrão correspondente SEMPRE funcione em paralelo
		var default_arrow_key: Key = DEFAULT_ARROW_KEYS.get(action, KEY_NONE)
		if default_arrow_key != KEY_NONE and default_arrow_key != keycode:
			var arrow_ev = InputEventKey.new()
			arrow_ev.physical_keycode = default_arrow_key
			InputMap.action_add_event(action, arrow_ev)

func _ensure_arrow_keys_registered() -> void:
	for action in RHYTHM_ACTIONS:
		var default_arrow_key: Key = DEFAULT_ARROW_KEYS.get(action, KEY_NONE)
		if default_arrow_key != KEY_NONE:
			var already_has = false
			for ev in InputMap.action_get_events(action):
				if ev is InputEventKey and ev.physical_keycode == default_arrow_key:
					already_has = true
					break
			if not already_has:
				var arrow_ev = InputEventKey.new()
				arrow_ev.physical_keycode = default_arrow_key
				InputMap.action_add_event(action, arrow_ev)

