extends Control

@export var score: int = 0
@export var combo: int = 0
@export var multiplier: int = 1
@export var compass_sum: float = 0.0
@export var compass_target: float = 4.0
@export var completed_compasses: int = 0

@export var score_value_label: Label
@export var combo_label: Label
@export var last_state: Label
@export var compass_label: Label
@export var equation_label: Label
@export var completed_label: Label
@export var bpm_label: Label
@export var metronome_dots_container: HBoxContainer
@export var measure_bar_container: HBoxContainer

var current_equation_parts: Array[String] = []

# Histórico de equações para o compasso
var _equation_history: Array[String] = []

func _ready() -> void:
	update_hud_displays()

# ─── GETTER PARA rhythm.gd ─────────────────────────────────────────────────

func get_completed_compasses() -> int:
	return completed_compasses

# ─── METRÔNOMO ────────────────────────────────────────────────────────────

func on_bpm_beat(beat_in_measure: int) -> void:
	# Pulso suave no texto de BPM
	if bpm_label:
		var tw = create_tween()
		tw.tween_property(bpm_label, "scale", Vector2(1.12, 1.12), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(bpm_label, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Atualiza os 4 marcadores visuais de metrônomo (● ○ ○ ○)
	if metronome_dots_container:
		var dots = metronome_dots_container.get_children()
		for i in range(dots.size()):
			var dot = dots[i] as Label
			if dot:
				if i + 1 == beat_in_measure:
					dot.text = "●"
					if beat_in_measure == 1:
						dot.add_theme_color_override("font_color", Color("#FFD166"))
					else:
						dot.add_theme_color_override("font_color", Color("#5CE1E6"))
					dot.scale = Vector2(1.2, 1.2)
					var dtw = create_tween()
					dtw.tween_property(dot, "scale", Vector2(1.0, 1.0), 0.15)
				else:
					dot.text = "○"
					dot.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
					dot.scale = Vector2(1.0, 1.0)

# ─── PONTUAÇÃO ────────────────────────────────────────────────────────────

func update_score(score_base: int) -> void:
	if score_base > 0:
		combo += 1
		multiplier = min(4, 1 + combo / 5)
		score += score_base * multiplier
	else:
		reset_combo()

	if score_value_label:
		score_value_label.text = String.num(score, 0)

	if combo_label:
		combo_label.text = "COMBO: x" + str(multiplier) + " (" + str(combo) + ")"
		if multiplier > 1:
			combo_label.add_theme_color_override("font_color", Color("#FFD166"))
		else:
			combo_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))

func reset_combo() -> void:
	combo = 0
	multiplier = 1
	if combo_label:
		combo_label.text = "COMBO: x1 (0)"
		combo_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))

# ─── NOTAS E COMPASSO (MATEMÁTICA) ────────────────────────────────────────

func add_note_to_compass(note_value: float, figure_name: String) -> void:
	compass_sum += note_value
	var frac_str = _format_val(note_value)
	current_equation_parts.append(figure_name + " (" + frac_str + "t)")

	if compass_sum >= compass_target - 0.001:
		completed_compasses += 1
		update_score(200)  # Bônus de fechamento de compasso

		# Monta equação completa do compasso fechado
		var eq_str = " + ".join(current_equation_parts) + " = 4t ✓"
		_equation_history.append(eq_str)

		update_last_state("★ COMPASSO %d/4 FECHADO! (+200) ★" % completed_compasses)

		# Se exceder 4 tempos, o resto vai para o próximo compasso
		compass_sum = max(0.0, compass_sum - compass_target)
		current_equation_parts.clear()

	update_hud_displays()

func _format_val(v: float) -> String:
	if is_equal_approx(v, 0.5):
		return "½"
	if is_equal_approx(v, 0.25):
		return "¼"
	return str(int(v))

# ─── ATUALIZAÇÃO DO HUD ────────────────────────────────────────────────────

func update_hud_displays() -> void:
	if compass_label:
		var pct = compass_sum / compass_target * 100.0
		compass_label.text = "Compasso: %.1f / 4.0t  (%.0f%%)" % [compass_sum, pct]

	if equation_label:
		if current_equation_parts.is_empty():
			if _equation_history.is_empty():
				equation_label.text = "Equação: (Toque as notas...)"
			else:
				# Mostra o último compasso fechado
				equation_label.text = "Último:  " + _equation_history[-1]
		else:
			# Equação em construção com soma parcial
			var soma = " + ".join(current_equation_parts)
			var running_sum = _format_val(compass_sum)
			equation_label.text = "Equação: %s = %st" % [soma, running_sum]

	if completed_label:
		completed_label.text = "Compassos Fechados: %d ★" % completed_compasses

	# Atualiza blocos visuais dos 4 tempos do compasso
	if measure_bar_container:
		var blocks = measure_bar_container.get_children()
		for i in range(blocks.size()):
			var block = blocks[i] as ProgressBar
			if block:
				var beat_fill = clampf(compass_sum - float(i), 0.0, 1.0)
				block.value = beat_fill

# ─── ESTADO DO HIT ────────────────────────────────────────────────────────

func update_last_state(state_text: String) -> void:
	if not last_state:
		return

	last_state.text = state_text
	var state_color: Color
	if "FECHADO" in state_text or "PERFEITO" in state_text or "VITÓRIA" in state_text or "CORRETO" in state_text:
		state_color = Color("#FFD166")
	elif "BOM" in state_text or "Semínima" in state_text:
		state_color = Color("#06D6A0")
	elif state_text == "OK":
		state_color = Color("#5CE1E6")
	elif "VIDA" in state_text:
		state_color = Color("#FF4444")
	else:
		state_color = Color("#FF6B6B")  # ERROU/PASSOU

	last_state.add_theme_color_override("font_color", state_color)

	var tw = create_tween()
	last_state.scale = Vector2(1.25, 1.25)
	last_state.modulate = Color(1.3, 1.3, 1.3, 1.0)
	tw.parallel().tween_property(last_state, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(last_state, "modulate", Color(1, 1, 1, 1), 0.2)
