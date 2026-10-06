extends Node2D


@export var falling_arrows : Node2D
@export var arrows: Node2D
@export var control: Control
@export var music_player: AudioStreamPlayer

var music_system = Music.new()
var notes = []
var current_note := 0
const FALL_TIME := 3.0

var quantity_falling_arrows := 30
var initial_position := [Vector2(496.0, 100.0), Vector2(640.0, 100.0), Vector2(352.0, 100.0), Vector2(784.0, 100.0)]
const FALLING_ARROW = preload("uid://doigxdyl6f2ss")


func _ready():
	notes = music_system.musics[0]
	music_player.play()


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


func check_arrow_pressed(arrow):
	var perfect = arrow.find_child("perfect")
	var good_ok = arrow.find_child("good_ok")
	
	if perfect.has_overlapping_areas():
		var falling_arrow_in_contact = perfect.get_overlapping_areas()[0].get_parent()
		
		control.update_score(100)
		control.update_last_state("PERFECT")
		print("Pressed at perfect")
		
		falling_arrow_in_contact.find_child("sprite").self_modulate = Color("#75dede")
		falling_arrow_in_contact.free()
	elif good_ok.has_overlapping_areas():
		var falling_arrow_in_contact = good_ok.get_overlapping_areas()[0].get_parent()
		
		if falling_arrow_in_contact.state == "GOOD":
			print("Pressed at ", falling_arrow_in_contact.state)
			control.update_score(60)
			control.update_last_state("GOOD")
		else:
			print("Pressed at ", falling_arrow_in_contact.state)
			control.update_score(30)
			control.update_last_state("OK")
		
		
		falling_arrow_in_contact.find_child("sprite").self_modulate = Color("#75dede")
		falling_arrow_in_contact.free()


func generate_arrow(orientation: int = 0, _position: Vector2 = initial_position[0]):
	var new_arrow = FALLING_ARROW.instantiate()
	match orientation:
		-90:
			new_arrow.direction = "UP"
		90:
			new_arrow.direction = "DOWN"
		0:
			new_arrow.direction = "RIGHT"
		-180:
			new_arrow.direction = "LEFT"
	add_child(new_arrow)
	new_arrow.reparent(falling_arrows)
	
	new_arrow.find_child("sprite").set_rotation_degrees(orientation)
	new_arrow.position = _position


func _on_falling_arrows_child_entered_tree(node: Node) -> void:
	# print("New child: ", node)
	await generate_fall(node)


func generate_note(note):
	match note["arrow"]:
		music_system.Arrow.LEFT:
			generate_arrow(-180, initial_position[2])
		
		music_system.Arrow.DOWN:
			generate_arrow(90, initial_position[1])
		
		music_system.Arrow.UP:
			generate_arrow(-90, initial_position[0])
		
		music_system.Arrow.RIGHT:
			generate_arrow(0, initial_position[3])


func generate_fall(arrow):
	var tween = get_tree().create_tween()
	var fall_to
	print(arrow.direction)
	match arrow.direction:
		"UP":
			fall_to = initial_position[0]
		"DOWN":
			fall_to = initial_position[1]
		"LEFT":
			fall_to = initial_position[2]
		"RIGHT":
			fall_to = initial_position[3]
	print(fall_to)
	tween.tween_property(arrow, "position", Vector2(fall_to.x, fall_to.y + 600), 3.0)


func _process(_delta):
	if !music_player.playing:
		return
	
	var current_time = music_player.get_playback_position()
	
	while current_note < notes.size():
		var note = notes[current_note]
		var spawn_time = note["time"] - FALL_TIME
		
		if current_time >= spawn_time:
			generate_note(note)
			current_note += 1
		else:
			break
	
	if current_note >= notes.size():
		await get_tree().create_timer(3).timeout
		get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")
