extends Node3D

@onready var ring_1 = $MeshInstance3D1
@onready var ring_2 = $MeshInstance3D2
@onready var ring_3 = $MeshInstance3D2/MeshInstance3D3

func _process(delta: float) -> void:
	ring_1.rotate_object_local(Vector3.DOWN, 3.0 * delta)
	ring_2.rotate_object_local(Vector3.RIGHT, 1.5 * delta)
	ring_3.rotate_object_local(Vector3.RIGHT, 1.5 * delta)
