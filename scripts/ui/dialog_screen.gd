extends Control
class_name DialogScreen

signal passou_de_fala(index: int)
signal dialogo_finalizado

var _step: float = 0.05
var _id: int = 0
var data: Dictionary = {}

@export_category("Objects")
@export var _name: Label = null
@export var _dialog: RichTextLabel = null
@export var _faceset: TextureRect = null
@export var _space_action_label: Label = null
@export var _space_keycap: PanelContainer = null
@export var _animation_player: AnimationPlayer = null


func _ready() -> void:
	if _animation_player and _animation_player.has_animation("pulse"):
		_animation_player.play("pulse")
	_initialize_dialog()


func _process(_delta: float) -> void:
	var is_typing: bool = _dialog.visible_ratio < 1.0

	if is_typing:
		if _space_action_label:
			_space_action_label.text = "Acelerar >>"
		
		if Input.is_action_pressed("ui_accept"):
			_step = 0.01
			_set_keycap_pressed(true)
			return
		else:
			_step = 0.05
			_set_keycap_pressed(false)
	else:
		_set_keycap_pressed(false)
		if _space_action_label:
			_space_action_label.text = "Avancar >"

	if Input.is_action_just_pressed("ui_accept"):
		_id += 1
		if _id >= data.size():
			dialogo_finalizado.emit()
			queue_free()
			return
		_initialize_dialog()


func _set_keycap_pressed(pressed: bool) -> void:
	if _space_keycap:
		_space_keycap.modulate = Color(0.4, 1.0, 0.7, 1.0) if pressed else Color(1.0, 1.0, 1.0, 1.0)


func _initialize_dialog() -> void:
	if data.is_empty() or not data.has(_id):
		return

	passou_de_fala.emit(_id)

	if data[_id].has("title") and _name:
		_name.text = data[_id]["title"]
	if data[_id].has("dialog") and _dialog:
		_dialog.text = data[_id]["dialog"]
	if data[_id].has("faceset") and _faceset:
		_faceset.texture = load(data[_id]["faceset"])
	
	if _dialog:
		_dialog.visible_characters = 0
		while _dialog.visible_ratio < 1:
			await get_tree().create_timer(_step).timeout
			_dialog.visible_characters += 1
