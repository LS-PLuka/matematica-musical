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
# Velocidade desacelerada para permitir leitura prévia e reação tranquila (3.2s)
const FALL_TIME: float = 3.2
const SPAWN_Y: float = 75.0
const TARGET_Y: float = 520.0

# 4 Pistas musicais centralizadas na Lousa (Lanes 0 a 3)
var lane_x: Array[float] = [376.0, 509.0, 643.0, 776.0]

const FALLING_ARROW = preload("uid://doigxdyl6f2ss")

var beat_interval: float = 60.0 / BPM # 0.5s por batida em 120 BPM
var last_beat_idx: int = -1

func _ready() -> void:
	notes = music_system.musics[0]
	setup_receptors()
	music_player.play()

func setup_receptors() -> void:
	if not arrows:
		return
	
	var receptor_configs = [
		{"name": "left", "lane": 0, "key": "A", "arrow": "←", "fig": "Semibreve", "val": "4t", "color": Color("#FF6B9D"), "tex": "res://assets/sprites/ui/semibreve.png"},
		{"name": "down", "lane": 1, "key": "S", "arrow": "↓", "fig": "Mínima", "val": "2t", "color": Color("#5CE1E6"), "tex": "res://assets/sprites/ui/minima.png"},
		{"name": "up", "lane": 2, "key": "W", "arrow": "↑", "fig": "Semínima", "val": "1t", "color": Color("#FFD166"), "tex": "res://assets/sprites/ui/seminima.png"},
		{"name": "right", "lane": 3, "key": "D", "arrow": "→", "fig": "Colcheia", "val": "½t", "color": Color("#06D6A0"), "tex": "res://assets/sprites/ui/colcheia.png"}
	]
	
	for cfg in receptor_configs:
		var rec = arrows.find_child(cfg["name"]) as Node2D
		if rec:
			rec.position = Vector2(lane_x[cfg["lane"]], TARGET_Y)
			if rec.has_method("setup_visuals"):
				rec.lane_index = cfg["lane"]
				rec.action_name = cfg["name"]
				rec.key_name = cfg["key"]
				rec.arrow_symbol = cfg["arrow"]
				rec.note_name = cfg["fig"]
				rec.note_value = cfg["val"]
				rec.accent_color = cfg["color"]
				rec.note_texture_path = cfg["tex"]
				rec.setup_visuals()

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	
	if Input.is_action_just_pressed("left"):
		handle_lane_press(0, "left")
	if Input.is_action_just_pressed("down"):
		handle_lane_press(1, "down")
	if Input.is_action_just_pressed("up"):
		handle_lane_press(2, "up")
	if Input.is_action_just_pressed("right"):
		handle_lane_press(3, "right")

func handle_lane_press(lane_index: int, action_name: String) -> void:
	if arrows:
		var receptor = arrows.find_child(action_name)
		if receptor:
			if receptor.has_method("play_click"):
				receptor.play_click()
			elif receptor.has_node("animation"):
				var anim = receptor.find_child("animation") as AnimationPlayer
				if anim and anim.has_animation("click"):
					anim.stop()
					anim.play("click")
		
		check_hit_for_lane(lane_index)

func check_hit_for_lane(lane_index: int) -> void:
	if not music_player or not music_player.playing:
		return
	
	var candidate_note: falling_arrow = null
	var min_dist: float = 99999.0
	
	for note_node in active_notes:
		if is_instance_valid(note_node) and note_node is falling_arrow:
			if note_node.note_info.get("lane", -1) == lane_index:
				var dist = abs(note_node.position.y - TARGET_Y)
				if dist < min_dist:
					min_dist = dist
					candidate_note = note_node
	
	# Janela de tolerância em pixels (com velocidade de ~140 px/s):
	# Perfect: <= 24px (~0.17s)
	# Good: <= 48px (~0.34s)
	# OK: <= 72px (~0.51s)
	if candidate_note and min_dist <= 72.0:
		var hit_rating = "OK"
		var score_add = 30
		
		if min_dist <= 24.0:
			hit_rating = "PERFEITO!"
			score_add = 100
		elif min_dist <= 48.0:
			hit_rating = "MUITO BOM!"
			score_add = 60
		
		var note_val: float = candidate_note.note_info.get("value", 1.0)
		var figure_name: String = candidate_note.note_info.get("name", "Nota")
		
		if control:
			control.update_score(score_add)
			control.update_last_state(hit_rating)
			control.add_note_to_compass(note_val, figure_name)
		
		active_notes.erase(candidate_note)
		var tw = create_tween()
		tw.parallel().tween_property(candidate_note, "scale", candidate_note.scale * 1.3, 0.1)
		tw.parallel().tween_property(candidate_note, "modulate:a", 0.0, 0.1)
		tw.tween_callback(candidate_note.queue_free)
	else:
		if control:
			control.reset_combo()
			control.update_last_state("ERROU!")

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

func _process(_delta: float) -> void:
	if not music_player or not music_player.playing:
		return
	
	var current_time = music_player.get_playback_position()
	
	# Metrônomo BPM sincronizado com áudio (sem drift)
	var current_beat = int(floor(current_time / beat_interval))
	if current_beat > last_beat_idx:
		last_beat_idx = current_beat
		trigger_bpm_pulse(current_beat)
	
	# Spawna notas da fila com antecipação suave (FALL_TIME = 3.2s)
	while current_note_idx < notes.size():
		var note = notes[current_note_idx]
		var spawn_time = note["time"] - FALL_TIME
		
		if current_time >= spawn_time:
			spawn_falling_note(note)
			current_note_idx += 1
		else:
			break
	
	# Atualiza posição das notas na pauta da lousa
	var to_remove: Array = []
	for note_node in active_notes:
		if is_instance_valid(note_node):
			var prog = 1.0 - (note_node.target_time - current_time) / FALL_TIME
			var current_y = lerp(SPAWN_Y, TARGET_Y, prog)
			note_node.position = Vector2(note_node.initial_pos.x, current_y)
			
			# Miss automático se passar da linha alvo (prog > 1.15)
			if prog > 1.15:
				to_remove.append(note_node)
		else:
			to_remove.append(note_node)
	
	for missed in to_remove:
		active_notes.erase(missed)
		if is_instance_valid(missed):
			if control:
				control.reset_combo()
				control.update_last_state("PASSOU!")
			missed.queue_free()
	
	# Fim da música
	if current_note_idx >= notes.size() and active_notes.is_empty():
		set_process(false)
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/cutscenes/epilogo.tscn")

func trigger_bpm_pulse(beat_index: int) -> void:
	var beat_in_measure = (beat_index % 4) + 1
	if control and control.has_method("on_bpm_beat"):
		control.on_bpm_beat(beat_in_measure)
