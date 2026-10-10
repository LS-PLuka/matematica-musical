extends Node
## Gerenciador global do jogo. Carrega configurações persistentes (keybindings)
## ao iniciar, garantindo que as teclas customizadas estejam sempre ativas.

const KEYBINDING_CONFIG_PATH := "user://keybindings.cfg"

# Ações de ritmo mapeáveis
const RHYTHM_ACTIONS := ["left", "down", "up", "right"]

func _ready() -> void:
	_load_keybindings()

func _load_keybindings() -> void:
	if not FileAccess.file_exists(KEYBINDING_CONFIG_PATH):
		return  # usa bindings padrão do projeto

	var cfg = ConfigFile.new()
	if cfg.load(KEYBINDING_CONFIG_PATH) != OK:
		push_warning("GameManager: falha ao carregar keybindings.cfg")
		return

	for action in RHYTHM_ACTIONS:
		if not cfg.has_section_key("rhythm_keys", action):
			continue

		var key_name: String = cfg.get_value("rhythm_keys", action, "")
		if key_name.is_empty():
			continue

		var keycode = OS.find_keycode_from_string(key_name)
		if keycode == KEY_NONE:
			continue

		# Remove eventos de teclado antigos
		var old_events = InputMap.action_get_events(action)
		for ev in old_events:
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)

		# Registra a tecla customizada
		var new_event = InputEventKey.new()
		new_event.physical_keycode = keycode
		InputMap.action_add_event(action, new_event)
