extends StaticBody2D

class_name ArrowHandle

@export var lane_index: int = 0
@export var action_name: String = "left"
@export var key_name: String = "A"
@export var arrow_symbol: String = "←"
@export var note_name: String = "Semibreve"
@export var note_value: String = "4t"
@export var note_texture_path: String = "res://assets/sprites/ui/semibreve.png"
@export var accent_color: Color = Color("#FF6B9D")

@onready var slot_bg: Panel = $slot_bg
@onready var sprite: Sprite2D = $sprite
@onready var key_label: Label = $key_label
@onready var value_label: Label = $value_label
@onready var animation: AnimationPlayer = $animation

func _ready() -> void:
	setup_visuals()

func setup_visuals() -> void:
	if sprite and ResourceLoader.exists(note_texture_path):
		var tex = load(note_texture_path)
		if tex:
			sprite.texture = tex
			sprite.scale = Vector2(0.044, 0.044)
			sprite.modulate = Color(accent_color.r, accent_color.g, accent_color.b, 0.55)
	
	if key_label:
		key_label.text = "[ " + key_name + " / " + arrow_symbol + " ]"
		key_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	
	if value_label:
		value_label.text = note_value
		value_label.add_theme_color_override("font_color", accent_color)

func play_click() -> void:
	if animation and animation.has_animation("click"):
		if animation.is_playing():
			animation.stop()
		animation.play("click")
	else:
		# Fallback tween se animação não existir
		var tw = create_tween()
		scale = Vector2(1.15, 1.15)
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
