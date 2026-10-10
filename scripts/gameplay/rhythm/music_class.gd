extends Node
class_name Music

enum Arrow {
	LEFT,   # Semibreve (4.0 tempos)
	DOWN,   # Mínima (2.0 tempos)
	UP,     # Semínima (1.0 tempo)
	RIGHT   # Colcheia (0.5 tempo)
}

const BPM := 120.0
const MEASURE_TARGET := 4.0 # Compasso 4/4

static func get_note_info(arrow_type: Arrow) -> Dictionary:
	match arrow_type:
		Arrow.LEFT:
			return {
				"lane": 0,
				"direction": "LEFT",
				"name": "Semibreve",
				"value": 4.0,
				"value_str": "4",
				"color": Color("#FF2E93"), # Rosa/Magenta Neon
				"texture": "res://assets/sprites/ui/semibreve.png"
			}
		Arrow.DOWN:
			return {
				"lane": 1,
				"direction": "DOWN",
				"name": "Mínima",
				"value": 2.0,
				"value_str": "2",
				"color": Color("#00F0FF"), # Ciano Neon
				"texture": "res://assets/sprites/ui/minima.png"
			}
		Arrow.UP:
			return {
				"lane": 2,
				"direction": "UP",
				"name": "Semínima",
				"value": 1.0,
				"value_str": "1",
				"color": Color("#FFDD00"), # Amarelo Neon
				"texture": "res://assets/sprites/ui/seminima.png"
			}
		Arrow.RIGHT:
			return {
				"lane": 3,
				"direction": "RIGHT",
				"name": "Colcheia",
				"value": 0.5,
				"value_str": "1/2",
				"color": Color("#00FF66"), # Verde Neon
				"texture": "res://assets/sprites/ui/colcheia.png"
			}
	return {}

var musica_encerramento = [
	{"time": 6.8, "arrow": Arrow.LEFT},
	{"time": 7.7, "arrow": Arrow.DOWN},
	{"time": 8.2, "arrow": Arrow.UP},
	{"time": 9.1, "arrow": Arrow.RIGHT},
	{"time": 9.6, "arrow": Arrow.RIGHT},
	{"time": 10.0, "arrow": Arrow.UP},
	{"time": 10.5, "arrow": Arrow.DOWN},
	{"time": 11.3, "arrow": Arrow.LEFT},
	{"time": 11.8, "arrow": Arrow.LEFT},
	{"time": 12.2, "arrow": Arrow.UP},
	{"time": 12.8, "arrow": Arrow.DOWN},
	{"time": 13.7, "arrow": Arrow.RIGHT},
	{"time": 14.0, "arrow": Arrow.LEFT},
	{"time": 14.5, "arrow": Arrow.RIGHT},
	{"time": 15.1, "arrow": Arrow.DOWN},
	{"time": 16.0, "arrow": Arrow.UP},
	{"time": 16.9, "arrow": Arrow.DOWN},
	{"time": 17.4, "arrow": Arrow.LEFT},
	{"time": 17.7, "arrow": Arrow.UP},
	{"time": 18.2, "arrow": Arrow.RIGHT},
	{"time": 19.1, "arrow": Arrow.UP},
	{"time": 19.7, "arrow": Arrow.LEFT},
	{"time": 20.8, "arrow": Arrow.DOWN},
	{"time": 21.4, "arrow": Arrow.RIGHT},
	{"time": 22.0, "arrow": Arrow.LEFT},
	{"time": 22.2, "arrow": Arrow.DOWN},
	{"time": 22.9, "arrow": Arrow.UP},
	{"time": 23.5, "arrow": Arrow.RIGHT},
	{"time": 24.3, "arrow": Arrow.RIGHT},
	{"time": 25.2, "arrow": Arrow.UP},
	{"time": 26.0, "arrow": Arrow.DOWN},
	{"time": 27.4, "arrow": Arrow.LEFT},
	{"time": 28.3, "arrow": Arrow.LEFT},
	{"time": 28.8, "arrow": Arrow.UP},
	{"time": 30.0, "arrow": Arrow.DOWN},
	{"time": 30.5, "arrow": Arrow.RIGHT},
	{"time": 31.1, "arrow": Arrow.LEFT},
	{"time": 31.4, "arrow": Arrow.RIGHT},
	{"time": 32.0, "arrow": Arrow.DOWN},
	{"time": 32.7, "arrow": Arrow.UP},
	{"time": 33.4, "arrow": Arrow.DOWN},
	{"time": 34.3, "arrow": Arrow.LEFT},
	{"time": 35.2, "arrow": Arrow.UP},
	{"time": 35.7, "arrow": Arrow.RIGHT},
	{"time": 36.5, "arrow": Arrow.UP},
	{"time": 38.0, "arrow": Arrow.LEFT},
	{"time": 39.1, "arrow": Arrow.DOWN},
	{"time": 39.6, "arrow": Arrow.RIGHT},
	{"time": 40.3, "arrow": Arrow.LEFT},
	{"time": 41.1, "arrow": Arrow.DOWN},
	{"time": 41.8, "arrow": Arrow.UP},
	{"time": 42.5, "arrow": Arrow.RIGHT},
	{"time": 43.5, "arrow": Arrow.RIGHT},
	{"time": 44.3, "arrow": Arrow.UP},
	{"time": 45.7, "arrow": Arrow.DOWN},
	{"time": 46.5, "arrow": Arrow.LEFT},
	{"time": 47.1, "arrow": Arrow.LEFT},
	{"time": 48.3, "arrow": Arrow.UP},
	{"time": 48.8, "arrow": Arrow.DOWN},
	{"time": 49.4, "arrow": Arrow.RIGHT},
	{"time": 50.3, "arrow": Arrow.LEFT},
	{"time": 51.0, "arrow": Arrow.RIGHT},
	{"time": 51.7, "arrow": Arrow.DOWN},
	{"time": 52.6, "arrow": Arrow.UP},
	{"time": 53.4, "arrow": Arrow.DOWN},
	{"time": 54.0, "arrow": Arrow.LEFT},
	{"time": 55.7, "arrow": Arrow.UP},
	{"time": 56.3, "arrow": Arrow.RIGHT},
	{"time": 57.4, "arrow": Arrow.UP},
	{"time": 57.9, "arrow": Arrow.LEFT},
	{"time": 58.5, "arrow": Arrow.DOWN},
	{"time": 59.4, "arrow": Arrow.RIGHT},
	{"time": 60.1, "arrow": Arrow.LEFT},
	{"time": 60.8, "arrow": Arrow.DOWN},
	{"time": 61.8, "arrow": Arrow.UP},
	{"time": 62.6, "arrow": Arrow.RIGHT},
	{"time": 63.1, "arrow": Arrow.RIGHT},
	{"time": 64.3, "arrow": Arrow.UP},
	{"time": 64.8, "arrow": Arrow.DOWN},
	{"time": 65.4, "arrow": Arrow.LEFT},
	{"time": 66.5, "arrow": Arrow.LEFT},
	{"time": 67.1, "arrow": Arrow.UP},
	{"time": 67.7, "arrow": Arrow.DOWN},
	{"time": 68.6, "arrow": Arrow.RIGHT},
	{"time": 68.8, "arrow": Arrow.LEFT},
	{"time": 70.0, "arrow": Arrow.RIGHT},
	{"time": 71.8, "arrow": Arrow.DOWN},
	{"time": 72.3, "arrow": Arrow.UP},
	{"time": 73.1, "arrow": Arrow.DOWN},
	{"time": 73.4, "arrow": Arrow.LEFT},
	{"time": 74.0, "arrow": Arrow.UP},
	{"time": 74.5, "arrow": Arrow.RIGHT},
	{"time": 76.6, "arrow": Arrow.UP},
]

var musics = [musica_encerramento]

