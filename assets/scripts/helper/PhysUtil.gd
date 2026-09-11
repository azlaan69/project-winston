extends Node

func raycast_from_cam(cam: Camera3D, distance: float = 100.0, exclude: Array[RID] = [], offset: Vector3 = Vector3.ZERO) -> Dictionary:
	var space_state = cam.get_world_3d().direct_space_state
	var origin = cam.global_position + offset
	var target = origin + (-cam.global_transform.basis.z * distance)
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = exclude
	return space_state.intersect_ray(query)

func get_target_in_cone(from: Vector3, dir: Vector3, distance: float = 80.0, radius: float = 4.0, exclude: Array[RID] = []) -> Vector3:
	var space_state = Engine.get_main_loop().current_scene.get_world_3d().direct_space_state
	
	var shape = SphereShape3D.new()
	shape.radius = radius
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = from + (dir.normalized() * (distance * 0.35))
	query.exclude = exclude
	
	var result = space_state.intersect_shape(query)
	
	var best_dir = (dir + Vector3(0.0, 0.1, 0.0)).normalized()
	var best_score = -1.0
	var closest_dist = 9999.0
	for res in result:
		var body = res.collider
		if body.is_in_group("enemy"):
			var to_enemy = (body.global_position - from).normalized()
			var dist = from.distance_to(body.global_position)
			
			var dot = dir.dot(to_enemy)
			if dot > 0.5:
				var score = dot - (dist / distance) * 0.3
				if score > best_score and dist < closest_dist:
					closest_dist = dist
					best_dir = to_enemy
					
	return best_dir
