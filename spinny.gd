extends Node3D

@onready var ring_1 = $Ring1
@onready var ring_2 = $Ring1/Ring2
@onready var ring_3 = $Ring1/Ring2/Ring3

func _process(delta: float) -> void:
	ring_1.rotate_object_local(Vector3.RIGHT, 1.5 * delta)
	ring_2.rotate_object_local(Vector3.RIGHT, 1.5 * delta)
	ring_3.rotate_object_local(Vector3.UP, 1.5 * delta)
