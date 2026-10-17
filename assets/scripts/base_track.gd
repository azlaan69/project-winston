extends Node3D

var height_error: float = 0.0

@export var ray: RayCast3D
@export var mesh: MeshInstance3D
@export var target_height: float = 3.0

@export_group("Visual")
@export var min_droop: float = -2.0
@export var max_droop: float = 2.0
@export var mesh_modifier: float = 1.0
@export var mesh_update_rate: float = 20.0

func _physics_process(delta: float) -> void:
	if ray.is_colliding():
		var hit_d = ray.global_position.distance_to(ray.get_collision_point())
		height_error = target_height - hit_d
	else:
		height_error = 0.0
	
	var target_mesh_y = height_error * mesh_modifier
	target_mesh_y = clampf(target_mesh_y, min_droop, max_droop)
	mesh.position.y = lerp(mesh.position.y, target_mesh_y, mesh_update_rate * delta)

func get_ray_normal() -> Vector3:
	return ray.get_collision_normal()
