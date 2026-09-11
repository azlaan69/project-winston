extends Node

func raycast_from_cam(cam: Camera3D, distance: float = 100.0, exclude: Array[RID] = [], offset: Vector3 = Vector3.ZERO) -> Dictionary:
	var space_state = cam.get_world_3d().direct_space_state
	var origin = cam.global_position + offset
	var target = origin + (-cam.global_transform.basis.z * distance)
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = exclude
	return space_state.intersect_ray(query)

func get_target_in_cone(from: Vector3, dir: Vector3, distance: float = 80.0, radius: float = 4.0, exclude: Array[RID] = []) -> Vector3:
	var norm_dir = dir.normalized()
	var space_state = Engine.get_main_loop().current_scene.get_world_3d().direct_space_state
	
	var shape = BoxShape3D.new()
	shape.size = Vector3(radius * 2.0, radius * 2.0, distance)
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = from + (norm_dir * (distance * 0.5))
	query.exclude = exclude
	
	if abs(norm_dir.y) < 0.99:
		query.transform.basis = Basis.looking_at(norm_dir, Vector3.UP)
	
	var results = space_state.intersect_shape(query)
	for r in results:
		var body = r.collider
		if is_instance_valid(body) and body.is_in_group("enemy"):
			print(body)
			return (body.global_position + Vector3(0, 0.9, 0) - from).normalized()
	
	return norm_dir
