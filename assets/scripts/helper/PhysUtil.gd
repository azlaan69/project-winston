extends Node

func raycast_from_cam(cam: Camera3D, distance: float = 100.0, exclude: Array[RID] = [], offset: Vector3 = Vector3.ZERO, include_areas: bool = false, mask: int = 3) -> Dictionary:
	var space_state = cam.get_world_3d().direct_space_state
	var origin = cam.global_position + offset
	var target = origin + (-cam.global_transform.basis.z * distance)
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = exclude
	query.collide_with_areas = include_areas
	query.collision_mask = mask
	return space_state.intersect_ray(query)

func shapecast_from_cam(cam: Camera3D, distance: float = 100.0, exclude: Array[RID] = [], radius: float = 0.5, offset: Vector3 = Vector3.ZERO, include_areas: bool = false, mask: int = 3) -> Variant:
	var space_state = cam.get_world_3d().direct_space_state
	var origin = cam.global_position + offset
	var motion_vector = (-cam.global_transform.basis.z * distance)
	
	var shape = CylinderShape3D.new()
	shape.radius = radius
	shape.height = 1.0
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = cam.global_transform
	query.transform.origin = origin
	query.motion = motion_vector
	query.exclude = exclude
	query.collide_with_areas = include_areas
	query.collision_mask = mask
	
	var motion_results: PackedFloat32Array = space_state.cast_motion(query)
	if motion_results.is_empty() or motion_results[1] >= 1.0:
		return null
	
	var collision_fraction = motion_results[1]
	query.transform.origin += motion_vector * collision_fraction
	var rest_info: Dictionary = space_state.get_rest_info(query)
	
	var hit_collider: Object = null
	if rest_info.has("collider_id"):
		hit_collider = instance_from_id(rest_info["collider_id"])
	
	return {
		"collider": hit_collider,
		"position": rest_info.get("point"),
		"normal": rest_info.get("normal")
	}

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
			var offset = Vector3(0, 0.9, 0)
			if body.has_node("hit_marker"):
				var hit_marker = body.get_child("hit_marker")
				offset = hit_marker.global_position 
			return (body.global_position + offset - from).normalized()
	
	return norm_dir

func hitstop(dur: float = 0.1) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = 1.0

func undulate(amount: float = 0.5, dur: float = 0.1) -> void:
	Engine.time_scale = amount
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = 1.0

func ghost(root: Node3D, mat: StandardMaterial3D, duration: float) -> void:
	if not root or not mat: return
	var ghost = root.duplicate()
	get_parent().add_child(ghost)
	ghost.global_transform = root.global_transform
	
	var ghost_mat = mat.duplicate() as StandardMaterial3D
	
	for child in ghost.find_children("*", "MeshInstance3D", true, false):
		var mesh_child = child as MeshInstance3D
		mesh_child.material_override = ghost_mat
	
	var tween = create_tween()
	tween.tween_property(ghost_mat, "albedo_color:a", 0.0, duration)
	tween.tween_callback(ghost.queue_free)
