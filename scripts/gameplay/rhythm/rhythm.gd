extends Node2D

@export var falling_arrows: Node2D
@export var arrows: Node2D
@export var control: Control
@export var music_player: AudioStreamPlayer

var music_system = Music.new()
var notes: Array = []
var current_note_idx: int = 0
var active_notes: Array = []

const BPM: float = 120.0
const FALL_TIME: float = 2.0 # 2 segundos = 4 tempos no BPM 120
const SPAWN_Y: float = 70.0
const TARGET_Y: float = 520.0

# 4 Pistas Guitar Hero (Lanes 0 a 3)
var lane_x: Array[float] = [376.0, 509.0, 643.0, 776.0]

const FALLING_ARROW = preload("uid://doigxdyl6f2ss")

var beat_timer: float = 0.0
var beat_interval: float = 60.0 / BPM # 0.5 segundos por tempo

func _ready() -> void:
	notes = music_system.musics[0]
	
	# Garante a criação ou ajuste dos receptores e pistas visuais
	setup_highway_visuals()
	
	music_player.play()

func setup_highway_visuals() -> void:
	# Ajusta posições dos receptores existentes
	if arrows:
		var left_arr = arrows.find_child("left")
		var down_arr = arrows.find_child("down")
		var up_arr = arrows.find_child("up")
		var right_arr = arrows.find_child("right")
		
		if left_arr: left_arr.position = Vector2(lane_x[0], TARGET_Y)
		if down_arr: down_arr.position = Vector2(lane_x[1], TARGET_Y)
		if up_arr: up_arr.position = Vector2(lane_x[2], TARGET_Y)
		if right_arr: right_arr.position = Vector2(lane_x[3], TARGET_Y)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("left"):
		handle_lane_press(0, "left")
	elif Input.is_action_just_pressed("down"):
		handle_lane_press(1, "down")
	elif Input.is_action_just_pressed("up"):
		handle_lane_press(2, "up")
	elif Input.is_action_just_pressed("right"):
		handle_lane_press(3, "right")

func handle_lane_press(lane_index: int, action_name: String) -> void:
	if arrows:
		var receptor = arrows.find_child(action_name)
		if receptor and receptor.has_node("animation"):
			receptor.find_child("animation").play("click")
			check_hit_for_lane(receptor, lane_index)

func check_hit_for_lane(receptor: Node2D, lane_index: int) -> void:
	var perfect_area = receptor.find_child("perfect") as Area2D
	var good_ok_area = receptor.find_child("good_ok") as Area2D
	
	var best_note: Node2D = null
	var hit_rating: String = "MISS"
	var score_add: int = 0
	
	if perfect_area and perfect_area.has_overlapping_areas():
		var overlapping = perfect_area.get_overlapping_areas()
		for area in overlapping:
			var parent = area.get_parent()
			if parent is falling_arrow and parent in active_notes:
				best_note = parent
				hit_rating = "PERFECT"
				score_add = 100
				break
	elif good_ok_area and good_ok_area.has_overlapping_areas():
		var overlapping = good_ok_area.get_overlapping_areas()
		for area in overlapping:
			var parent = area.get_parent()
			if parent is falling_arrow and parent in active_notes:
				best_note = parent
				if parent.state == "GOOD":
					hit_rating = "GOOD"
					score_add = 60
				else:
					hit_rating = "OK"
					score_add = 30
				break
	
	if best_note:
		var note_val: float = best_note.note_info.get("value", 1.0)
		var figure_name: String = best_note.note_info.get("name", "Nota")
		
		if control:
			control.update_score(score_add)
			control.update_last_state(hit_rating)
			control.add_note_to_compass(note_val, figure_name)
		
		active_notes.erase(best_note)
		best_note.queue_free()
	else:
		if control:
			control.reset_combo()
			control.update_last_state("MISS")

func spawn_falling_note(note_data: Dictionary) -> void:
	var arrow_type = note_data.get("arrow", Music.Arrow.LEFT)
	var info = Music.get_note_info(arrow_type)
	var lane = info.get("lane", 0)
	var target_time = note_data.get("time", 0.0)
	
	var start_pos = Vector2(lane_x[lane], SPAWN_Y)
	var end_pos = Vector2(lane_x[lane], TARGET_Y)
	
	var new_arrow = FALLING_ARROW.instantiate() as falling_arrow
	falling_arrows.add_child(new_arrow)
	
	new_arrow.position = start_pos
	new_arrow.setup_note(info, target_time, start_pos, end_pos)
	active_notes.append(new_arrow)

func _process(delta: float) -> void:
	if not music_player or not music_player.playing:
		return
	
	var current_time = music_player.get_playback_position()
	
	# Metrônomo BPM Pulse
	beat_timer += delta
	if beat_timer >= beat_interval:
		beat_timer -= beat_interval
		trigger_bpm_pulse()
	
	# Spawna notas da fila sincronizadas com a música e tempo de queda
	while current_note_idx < notes.size():
		var note = notes[current_note_idx]
		var spawn_time = note["time"] - FALL_TIME
		
		if current_time >= spawn_time:
			spawn_falling_note(note)
			current_note_idx += 1
		else:
			break
	
	# Atualiza a posição de todas as notas ativas ao longo da pista
	var to_remove: Array = []
	for note_node in active_notes:
		if is_instance_valid(note_node):
			var prog = 1.0 - (note_node.target_time - current_time) / FALL_TIME
			var current_y = lerp(SPAWN_Y, TARGET_Y, prog)
			note_node.position = Vector2(note_node.initial_pos.x, current_y)
			
			# Miss automático se passar muito da linha alvo
			if prog > 1.15:
				to_remove.append(note_node)
		else:
			to_remove.append(note_node)
	
	for missed in to_remove:
		active_notes.erase(missed)
		if is_instance_valid(missed):
			if control:
				control.reset_combo()
				control.update_last_state("MISS")
			missed.queue_free()
	
	# Checa fim de música
	if current_note_idx >= notes.size() and active_notes.is_empty():
		set_process(false)
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/cutscenes/epilogo.tscn")

func trigger_bpm_pulse() -> void:
	if control and control.bpm_label:
		var tw = create_tween()
		tw.tween_property(control.bpm_label, "scale", Vector2(1.15, 1.15), 0.08)
		tw.tween_property(control.bpm_label, "scale", Vector2(1.0, 1.0), 0.12)
