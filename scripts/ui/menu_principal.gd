extends Control

@export var start: Button

const CAMINHO_AUDIO_TV := "res://assets/audio/sfx/tv_on.mp3"
const KEYBINDING_SCENE = preload("res://scenes/ui/keybinding_menu.tscn")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

	if start:
		start.grab_focus()

	_animar_tv_ligando()

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
	get_tree().change_scene_to_file("res://scenes/cutscenes/abertura.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_keybinding_pressed() -> void:
	# Adiciona em CanvasLayer dedicado para garantir que fique acima de
	# todos os outros nós e intercepte corretamente os eventos de mouse.
	var kb_canvas := CanvasLayer.new()
	kb_canvas.layer = 10
	add_child(kb_canvas)

	var kb_menu = KEYBINDING_SCENE.instantiate()
	kb_canvas.add_child(kb_menu)

	# O efeito VHS está numa CanvasLayer que renderiza por cima de tudo —
	# esconde enquanto as configs estão abertas.
	var vhs = find_child("VHSeffect") as CanvasLayer
	if vhs:
		vhs.visible = false

	kb_menu.closed.connect(func():
		if is_instance_valid(vhs):
			vhs.visible = true
		kb_canvas.queue_free()  # remove canvas + keybinding_menu
	)

func _on_focus_entered() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

func _on_focus_exited() -> void:
	pass
