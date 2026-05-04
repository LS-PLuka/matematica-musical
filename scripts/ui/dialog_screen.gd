extends Control
class_name DialogScreen

signal dialogo_finalizado

var _step: float = 0.05
var _id: int = 0
var data: Dictionary = {}

@export_category("Objects")
@export var _name: Label = null
@export var _dialog: RichTextLabel = null
@export var _faceset: TextureRect = null

func _ready() -> void:
	_initialize_dialog()

func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_accept") and _dialog.visible_ratio < 1:
		_step = 0.01
		return
	
	_step = 0.05
	if Input.is_action_just_pressed("ui_accept"):
		_id += 1
		if _id == data.size():
			dialogo_finalizado.emit()
			queue_free()
			return
		_initialize_dialog()

func _initialize_dialog() -> void:
	_name.text = data[_id]["title"]
	_dialog.text = data[_id]["dialog"]
	_faceset.texture = load(data[_id]["faceset"])
	_dialog.visible_characters = 0
	while _dialog.visible_ratio < 1:
		await get_tree().create_timer(_step).timeout
		_dialog.visible_characters += 1
		
