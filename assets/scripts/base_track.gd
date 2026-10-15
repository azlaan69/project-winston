extends Node3D

@export var ray: RayCast3D

func _physics_process(delta: float) -> void:
	global_position.y = ray.get_collision_point().y + 3.0

func get_ray_normal() -> Vector3:
	return ray.get_collision_normal()
