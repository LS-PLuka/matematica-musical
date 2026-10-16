extends Control

@export var start: Button

const CAMINHO_AUDIO_TV := "res://assets/audio/sfx/tv_on.mp3"
const KEYBINDING_SCENE = preload("res://scenes/ui/keybinding_menu.tscn")

var _btn_difficulty: Button = null
var _lbl_difficulty_info: Label = null
var _badge_unlocked: Label = null

# --- Variáveis do Reset Secreto ---
var _tempo_segurando_reset: float = 0.0
var _reset_ativado: bool = false
const TEMPO_PARA_RESET := 5.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

	_setup_difficulty_feature()
	_setup_menu_focus_chain()

	if start:
		start.call_deferred("grab_focus")

	_animar_tv_ligando()

func _process(delta: float) -> void:
	if _reset_ativado:
		return
		
	# Na Godot 4, usamos apenas KEY_CTRL para ambos os lados
	var segurando_ctrl = Input.is_physical_key_pressed(KEY_CTRL)
	var segurando_backspace = Input.is_physical_key_pressed(KEY_BACKSPACE)
	
	if segurando_ctrl and segurando_backspace:
		_tempo_segurando_reset += delta
		if _tempo_segurando_reset >= TEMPO_PARA_RESET:
			_reset_ativado = true
			_executar_reset_secreto()
	else:
		_tempo_segurando_reset = 0.0

func _setup_menu_focus_chain() -> void:
	var botoes = find_child("Botoes") as VBoxContainer
	if not botoes:
		return
	var buttons: Array[Button] = []
	for child in botoes.get_children():
		if child is Button and child.visible:
			buttons.append(child)
	for i in range(buttons.size()):
		var btn = buttons[i]
		var prev = buttons[(i - 1 + buttons.size()) % buttons.size()]
		var nxt = buttons[(i + 1) % buttons.size()]
		btn.focus_neighbor_top = btn.get_path_to(prev)
		btn.focus_neighbor_bottom = btn.get_path_to(nxt)
		btn.focus_previous = btn.get_path_to(prev)
		btn.focus_next = btn.get_path_to(nxt)

func _setup_difficulty_feature() -> void:
	if not GameManager.is_game_completed:
		return

	var font = load("res://assets/fonts/joystix monospace.otf") as FontFile
	var botoes = find_child("Botoes") as VBoxContainer
	if not botoes:
		return

	var margem = find_child("MargemBotoes") as MarginContainer
	if margem:
		margem.offset_top = -50.0
		margem.offset_bottom = 90.0

	# Badge comemorativo de desbloqueio
	if not _badge_unlocked:
		_badge_unlocked = Label.new()
		_badge_unlocked.text = "★ MODO DESBLOQUEADO ★"
		_badge_unlocked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if font:
			_badge_unlocked.add_theme_font_override("font", font)
		_badge_unlocked.add_theme_font_size_override("font_size", 10)
		_badge_unlocked.add_theme_color_override("font_color", Color("#FFD166"))
		_badge_unlocked.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		_badge_unlocked.add_theme_constant_override("outline_size", 3)
		botoes.add_child(_badge_unlocked)
		botoes.move_child(_badge_unlocked, 1)

		var tw = create_tween().set_loops()
		tw.tween_property(_badge_unlocked, "modulate:a", 0.4, 0.8)
		tw.tween_property(_badge_unlocked, "modulate:a", 1.0, 0.8)

	# Botão de alternar dificuldade
	if not _btn_difficulty:
		_btn_difficulty = Button.new()
		_btn_difficulty.name = "Dificuldade"
		_btn_difficulty.flat = true
		if font:
			_btn_difficulty.add_theme_font_override("font", font)
		_btn_difficulty.add_theme_font_size_override("font_size", 20)
		botoes.add_child(_btn_difficulty)
		botoes.move_child(_btn_difficulty, 2)

		_btn_difficulty.focus_entered.connect(_on_focus_entered)
		_btn_difficulty.pressed.connect(_on_difficulty_pressed)

	# Label descritivo do modificador atual
	if not _lbl_difficulty_info:
		_lbl_difficulty_info = Label.new()
		_lbl_difficulty_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl_difficulty_info.autowrap_mode = TextServer.AUTOWRAP_WORD
		if font:
			_lbl_difficulty_info.add_theme_font_override("font", font)
		_lbl_difficulty_info.add_theme_font_size_override("font_size", 9)
		_lbl_difficulty_info.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
		_lbl_difficulty_info.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		_lbl_difficulty_info.add_theme_constant_override("outline_size", 2)
		botoes.add_child(_lbl_difficulty_info)
		botoes.move_child(_lbl_difficulty_info, 3)

	_update_difficulty_display()
	_setup_menu_focus_chain()

func _update_difficulty_display() -> void:
	if _btn_difficulty:
		_btn_difficulty.text = "Dificuldade: [ %s ]" % GameManager.get_difficulty_name()
		_btn_difficulty.add_theme_color_override("font_color", GameManager.get_difficulty_color())
		_btn_difficulty.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		_btn_difficulty.add_theme_color_override("font_focus_color", GameManager.get_difficulty_color())
	if _lbl_difficulty_info:
		_lbl_difficulty_info.text = GameManager.get_difficulty_description()

func _on_difficulty_pressed() -> void:
	GameManager.cycle_difficulty()
	_update_difficulty_display()

	if _btn_difficulty:
		var tw = create_tween()
		tw.tween_property(_btn_difficulty, "scale", Vector2(1.08, 1.08), 0.08)
		tw.tween_property(_btn_difficulty, "scale", Vector2(1.0, 1.0), 0.08)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var tecla_pressionada = event.physical_keycode
		if tecla_pressionada == KEY_NONE:
			tecla_pressionada = event.keycode

		# Atalho F2 para desenvolvedor / testes rápidos de desbloqueio
		if tecla_pressionada == KEY_F2:
			GameManager.save_game_completed()
			_setup_difficulty_feature()
			if has_method("_update_difficulty_display"):
				_update_difficulty_display()

	if not event.is_pressed() or event.is_echo():
		return

	# Se nenhum botão estiver focado, restaura o foco no primeiro botão navegável
	var viewport = get_viewport()
	if viewport and viewport.gui_get_focus_owner() == null:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("up") or \
		   event.is_action_pressed("ui_down") or event.is_action_pressed("down") or \
		   event.is_action_pressed("ui_left") or event.is_action_pressed("left") or \
		   event.is_action_pressed("ui_right") or event.is_action_pressed("right") or \
		   event.is_action_pressed("ui_accept"):
			_restore_menu_focus()
			viewport.set_input_as_handled()

func _executar_reset_secreto() -> void:
	_tempo_segurando_reset = 0.0
	
	if GameManager.has_method("reset_save_data"):
		GameManager.reset_save_data()
		
	# Reseta as teclas mapeadas para o padrão
	if GameManager.has_method("reset_keybindings_to_default"):
		GameManager.reset_keybindings_to_default()
	
	var flash_canvas := CanvasLayer.new()
	flash_canvas.layer = 100
	add_child(flash_canvas)
	
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.8, 0.1, 0.1, 0.8) 
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_canvas.add_child(flash)
	
	var tw = create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.5)
	
	await tw.finished
	get_tree().reload_current_scene()

func _animar_tv_ligando() -> void:
	if ResourceLoader.exists(CAMINHO_AUDIO_TV):
		var audio_stream = load(CAMINHO_AUDIO_TV)
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.stream = audio_stream
		add_child(sfx_player)
		sfx_player.play()
		sfx_player.finished.connect(sfx_player.queue_free)

	var tv_flash := ColorRect.new()
	tv_flash.name = "EfeitoTVLigando"
	tv_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	tv_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv_flash.color = Color(1.0, 1.0, 1.0, 1.0)
	add_child(tv_flash)

	tv_flash.pivot_offset = tv_flash.size / 2.0
	tv_flash.scale = Vector2(1.0, 0.001)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(tv_flash, "scale", Vector2(1.0, 1.0), 0.7).from(Vector2(1.0, 0.001)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(tv_flash, "modulate:a", 0.0, 0.9).set_delay(0.15)

	await tween.finished
	tv_flash.queue_free()

func _on_start_pressed() -> void:
	if GameManager.is_game_completed:
		if is_instance_valid(SceneManager):
			SceneManager.ir_para("res://scenes/gameplay/rhythm/rhythm.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/gameplay/rhythm/rhythm.tscn")
	else:
		if is_instance_valid(SceneManager):
			SceneManager.ir_para("res://scenes/cutscenes/abertura.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/cutscenes/abertura.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_keybinding_pressed() -> void:
	var kb_canvas := CanvasLayer.new()
	kb_canvas.layer = 10
	add_child(kb_canvas)

	var kb_menu = KEYBINDING_SCENE.instantiate()
	kb_canvas.add_child(kb_menu)

	var vhs = find_child("VHSeffect") as CanvasLayer
	if vhs:
		vhs.visible = false

	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

	kb_menu.closed.connect(func():
		if is_instance_valid(vhs):
			vhs.visible = true
		kb_canvas.queue_free() 
		call_deferred("_restore_menu_focus")
	)

func _restore_menu_focus() -> void:
	var btn_teclas = find_child("Teclas") as Button
	if btn_teclas and btn_teclas.is_inside_tree() and btn_teclas.is_visible_in_tree():
		btn_teclas.grab_focus()
	elif start and start.is_inside_tree() and start.is_visible_in_tree():
		start.grab_focus()

func _on_focus_entered() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

func _on_focus_exited() -> void:
	pass
