extends Node3D

@export var ray: RayCast3D

func _physics_process(delta: float) -> void:
	if ray.is_colliding(): position.y = to_local(ray.get_collision_point()).y

func get_ray_normal() -> Vector3:
	return ray.get_collision_normal()
