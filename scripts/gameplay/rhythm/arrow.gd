extends StaticBody2D

class_name falling_arrow

@export var direction : String
@export var state : String = "MISS"

var target_time: float = 0.0
var note_info: Dictionary = {}
var initial_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO

func setup_note(info: Dictionary, t_time: float, start_p: Vector2, end_p: Vector2) -> void:
	note_info = info
	direction = info.get("direction", "LEFT")
	target_time = t_time
	initial_pos = start_p
	target_pos = end_p
	
	# Disco de fundo estilo token de lousa
	var bg_disc = find_child("bg_disc") as Panel
	if not bg_disc:
		bg_disc = Panel.new()
		bg_disc.name = "bg_disc"
		bg_disc.size = Vector2(54, 54)
		bg_disc.position = Vector2(-27, -27)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.11, 0.09, 0.9)
		style.border_color = info.get("color", Color(1, 1, 1, 0.9))
		style.set_border_width_all(2)
		style.set_corner_radius_all(27)
		bg_disc.add_theme_stylebox_override("panel", style)
		bg_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_disc)
		move_child(bg_disc, 0)
	
	var sprite = find_child("sprite") as Sprite2D
	if sprite:
		var tex_path = info.get("texture", "")
		if ResourceLoader.exists(tex_path):
			var tex = load(tex_path)
			if tex:
				sprite.texture = tex
				sprite.hframes = 1
				sprite.vframes = 1
				# Escala compacta e proporcional (~66px de largura)
				sprite.scale = Vector2(0.046, 0.046)
		sprite.modulate = info.get("color", Color.WHITE)
	
	var value_label = find_child("value_label") as Label
	if not value_label:
		value_label = Label.new()
		value_label.name = "value_label"
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value_label.position = Vector2(-25, 20)
		value_label.size = Vector2(50, 16)
		var font = load("res://assets/fonts/joystix monospace.otf")
		if font:
			value_label.add_theme_font_override("font", font)
		value_label.add_theme_font_size_override("font_size", 10)
		value_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		value_label.add_theme_constant_override("outline_size", 4)
		add_child(value_label)
	
	value_label.text = info.get("value_str", "1t")

# ENTRADA
func _on_ok_area_entered(_area: Area2D) -> void:
	state = "OK"

func _on_good_area_entered(_area: Area2D) -> void:
	state = "GOOD"

func _on_perfect_area_entered(_area: Area2D) -> void:
	state = "PERFECT"

# SAIDA
func _on_perfect_area_exited(_area: Area2D) -> void:
	state = "GOOD"

func _on_good_area_exited(_area: Area2D) -> void:
	state = "OK"

func _on_ok_area_exited(_area: Area2D) -> void:
	state = "MISS"
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self):
		free()
