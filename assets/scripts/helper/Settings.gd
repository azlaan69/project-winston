extends Node

var sens: float = 0.001

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func change_sens(val: float) -> void:
	sens = val

func quit() -> void:
	get_tree().quit()

func reset() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
