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
			return (body.global_position + Vector3(0, 0.9, 0) - from).normalized()
	
	return norm_dir

func hitstop(dur: float = 0.1) -> void:
	Engine.time_scale = 0.0
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
