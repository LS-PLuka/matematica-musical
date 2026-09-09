extends StaticBody2D

class_name falling_arrow

@export var state : String = "MISS"

# ENTRADA
func _on_ok_area_entered(_area: Area2D) -> void:
	state = "OK"
	# print("Estado atual: ", state)


func _on_good_area_entered(_area: Area2D) -> void:
	state = "GOOD"
	# print("Estado atual: ", state)


func _on_perfect_area_entered(_area: Area2D) -> void:
	state = "PERFECT"
	# print("Estado atual: ", state)

# SAIDA

func _on_perfect_area_exited(_area: Area2D) -> void:
	state = "GOOD"
	# print("Estado atual: ", state)


func _on_good_area_exited(_area: Area2D) -> void:
	state = "OK"
	# print("Estado atual: ", state)


func _on_ok_area_exited(_area: Area2D) -> void:
	state = "MISS"
	# print("Estado atual: ", state)
	await get_tree().create_timer(1).timeout
	free()
