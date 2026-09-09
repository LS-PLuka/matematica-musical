extends Node2D


@export var falling_arrows : Node2D
@export var arrows: Node2D
@export var control: Control

var quantity_falling_arrows := 0
var initial_position := Vector2(496.0, 100.0)
const FALLING_ARROW = preload("uid://doigxdyl6f2ss")


func _ready():
	initialize()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("up"):
		var up_arrow = arrows.find_child("up")
		up_arrow.find_child("animation").play("click")
		check_arrow_pressed(up_arrow)
	elif Input.is_action_just_pressed("down"):
		var down_arrow = arrows.find_child("down")
		down_arrow.find_child("animation").play("click")
		check_arrow_pressed(down_arrow)
	elif Input.is_action_just_pressed("left"):
		var left_arrow = arrows.find_child("left")
		left_arrow.find_child("animation").play("click")
		check_arrow_pressed(left_arrow)
	elif Input.is_action_just_pressed("right"):
		var right_arrow = arrows.find_child("right")
		right_arrow.find_child("animation").play("click")
		check_arrow_pressed(right_arrow)

	# PARA TESTES
	if Input.is_action_just_pressed("ui_accept"):
		generate_arrow(-90)


func check_arrow_pressed(arrow):
	var perfect = arrow.find_child("perfect")
	var good_ok = arrow.find_child("good_ok")
	
	if perfect.has_overlapping_areas():
		var falling_arrow_in_contact = perfect.get_overlapping_areas()[0].get_parent()
		
		control.update_score(100)
		print("Pressed at perfect")
		
		falling_arrow_in_contact.find_child("sprite").self_modulate = Color("#75dede")
		falling_arrow_in_contact.free()
	elif good_ok.has_overlapping_areas():
		var falling_arrow_in_contact = good_ok.get_overlapping_areas()[0].get_parent()
		
		if falling_arrow_in_contact.state == "GOOD":
			print("Pressed at ", falling_arrow_in_contact.state)
			control.update_score(60)
		else:
			print("Pressed at ", falling_arrow_in_contact.state)
			control.update_score(30)
		
		
		falling_arrow_in_contact.find_child("sprite").self_modulate = Color("#75dede")
		falling_arrow_in_contact.free()


func initialize():
	for arrow in quantity_falling_arrows:
		generate_arrow(90)
		await get_tree().create_timer(1).timeout


func generate_arrow(orientation: int = 0, _position: Vector2 = initial_position):
	var new_arrow = FALLING_ARROW.instantiate()
	add_child(new_arrow)
	new_arrow.reparent(falling_arrows)
	
	new_arrow.find_child("sprite").set_rotation_degrees(orientation)
	new_arrow.position = _position


func _on_falling_arrows_child_entered_tree(node: Node) -> void:
	# print("New child: ", node)
	await generate_fall(node)


func generate_fall(arrow):
	var tween = get_tree().create_tween()
	tween.tween_property(arrow, "position", Vector2(initial_position.x, initial_position.y + 600), 3.0)
