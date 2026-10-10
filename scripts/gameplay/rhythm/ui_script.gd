extends Control

@export var score: int = 0
@export var combo: int = 0
@export var multiplier: int = 1
@export var compass_sum: float = 0.0
@export var compass_target: float = 4.0
@export var completed_compasses: int = 0

@export var score_value_label: Label
@export var last_state: Label
@export var animation: AnimationPlayer

@export var combo_label: Label
@export var compass_label: Label
@export var equation_label: Label
@export var bpm_label: Label
@export var progress_bar: TextureProgressBar

var current_equation_parts: Array[String] = []

func _ready() -> void:
	update_hud_displays()

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
			combo_label.add_theme_color_override("font_color", Color("#FFDD00"))
		else:
			combo_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))

func reset_combo() -> void:
	combo = 0
	multiplier = 1
	if combo_label:
		combo_label.text = "COMBO: x1 (0)"
		combo_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))

func add_note_to_compass(note_value: float, figure_name: String) -> void:
	compass_sum += note_value
	current_equation_parts.append(figure_name + " (" + _format_val(note_value) + "t)")
	
	if compass_sum >= compass_target - 0.001:
		completed_compasses += 1
		update_score(200) # Bônus de soma do compasso
		if last_state:
			update_last_state("COMPASSO PERFEITO! 4/4 (+200 BÔNUS)")
		compass_sum = 0.0
		current_equation_parts.clear()
	
	update_hud_displays()

func _format_val(v: float) -> String:
	if is_equal_approx(v, 0.5):
		return "1/2"
	return str(int(v))

func update_hud_displays() -> void:
	if compass_label:
		compass_label.text = "Soma do Compasso: %.1f / 4.0 tempos" % compass_sum
	
	if equation_label:
		if current_equation_parts.is_empty():
			equation_label.text = "Equação: (Aguardando notas...)"
		else:
			equation_label.text = "Equação: " + " + ".join(current_equation_parts)
	
	if progress_bar:
		progress_bar.max_value = compass_target
		progress_bar.value = compass_sum

func update_last_state(state: String) -> void:
	if not last_state:
		return
	
	last_state.text = state
	var state_color: Color
	if "PERFEITO" in state or state == "PERFECT":
		state_color = Color("#FFDD00") # Amarelo Neon
	elif state == "GOOD":
		state_color = Color("#00FF66") # Verde Neon
	elif state == "OK":
		state_color = Color("#00F0FF") # Ciano Neon
	else:
		state_color = Color("#FF2E44") # Vermelho (MISS)
	
	last_state.add_theme_color_override("font_color", state_color)
	if animation and animation.has_animation("pulse"):
		if animation.is_playing():
			animation.stop()
		animation.play("pulse")

