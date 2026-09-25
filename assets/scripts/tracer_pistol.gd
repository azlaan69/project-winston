extends Node3D

var pos : Vector3
var speed := 150.0
var length := 0.5
var timer = 1.0
var is_set := false

func init(start_pos: Vector3, end_pos: Vector3) -> void:
	global_position = start_pos
	pos = end_pos
	if start_pos != end_pos:
		look_at(end_pos)
	is_set = true

func _process(delta: float) -> void:
	if not is_set: return
	timer -= delta
	global_position = global_position.move_toward(pos, speed * delta)
	if (global_position - pos).length() < length or timer <= 0.0: queue_free()
