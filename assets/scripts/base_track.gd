extends Node3D

@export var ray: RayCast3D
@export var mesh: MeshInstance3D

func _physics_process(delta: float) -> void:
	if ray.is_colliding(): 
		mesh.position.y = to_local(ray.get_collision_point()).y + 2.0

func get_ray_normal() -> Vector3:
	return ray.get_collision_normal()
