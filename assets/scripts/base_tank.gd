class_name BaseTank
extends CharacterBody3D

var player = null
var tracks: Array[Node] = []
var forward_dir = Vector3.FORWARD

var update_transform := true

@export var tracks_parent: Node3D

@export_group("Update")
@export var tracking_rate: float = 100.0
@export var steer_rate: float = 5.0
@export var top_speed: float = 25.0
@export var accel: float = 20.0
@export var y_pulse_rate: float = 2.0
@export var hover_rate: float = 10.0
@export var grav_force: float = 5.0

@export_group("Visuals")
@export var visual_update_rate: float = 20.0
@export var visual_update_modifier: float = 0.005
@export var mesh: VisualInstance3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	tracks = tracks_parent.get_children()

func update_chassis(delta, dir: Vector3, speed: float = top_speed) -> void:
	if update_transform:
		var norm = fetch_normal()
		
		var goal_basis = Basis.looking_at(dir, norm).orthonormalized()
		var clean_current_basis = global_transform.basis.orthonormalized()
		
		var q_goal = goal_basis.get_rotation_quaternion()
		var q_current = clean_current_basis.get_rotation_quaternion()
		
		var angle_diff = q_current.angle_to(q_goal)
		var max_step = deg_to_rad(tracking_rate) * delta
		var t = clampf(max_step / angle_diff, 0.0, 1.0) if angle_diff > 0.0001 else 1.0
		
		global_transform.basis = Basis(q_current.slerp(q_goal, t))
	
	
	
	var target_velocity = Vector2(dir.x, dir.z).normalized() * speed
	var flat_velocity = Vector2(velocity.x, velocity.z)
	var steer_rate_to_use = steer_rate if flat_velocity.dot(target_velocity) > 0.0 else steer_rate / 2.0
	
	flat_velocity = flat_velocity.lerp(target_velocity, steer_rate_to_use * delta)
	velocity.x = flat_velocity.x
	velocity.z = flat_velocity.y
	
	
	
	var average_error = fetch_height_error()
	var target_y_speed = average_error * hover_rate
	
	var colliding = fetch_if_colliding()
	if colliding:
		velocity.y = target_y_speed
	else:
		velocity.y -= grav_force * delta
	 

func update_chassis_visual(delta) -> void:
	var pulse_wave = sin(Time.get_ticks_msec() * 0.005) * y_pulse_rate
	var forward_movement = velocity.dot(global_transform.basis.z)
	var side_movement = velocity.dot(global_transform.basis.x)
	
	var pitch = forward_movement * visual_update_modifier
	var roll = side_movement * visual_update_modifier * 1.5
	
	mesh.rotation.x = lerp_angle(mesh.rotation.x, pitch, visual_update_rate * delta)
	mesh.rotation.z = lerp_angle(mesh.rotation.z, roll, visual_update_rate * delta)

	mesh.position.y += -pulse_wave
	
	tracks_parent.position.y += pulse_wave
	tracks_parent.rotation = mesh.rotation
	
	
func get_rot_to_player() -> Vector3:
	var norm = fetch_normal()
	var dir_to_player = global_position.direction_to(player.global_position)
	var flat_dir = dir_to_player.slide(norm)
	if flat_dir.is_zero_approx():
		flat_dir = -global_transform.basis.z.slide(norm)
	flat_dir = flat_dir.normalized()
	return flat_dir

func fetch_normal() -> Vector3:
	var average_normal = Vector3.ZERO
	for i in tracks:
		if i.ray.is_colliding():
			var normal = i.get_ray_normal()
			average_normal += normal
	average_normal = average_normal.normalized()
	if !average_normal.is_equal_approx(Vector3.ZERO): return average_normal
	else: return Vector3.UP

func fetch_height_error() -> float:
	var average_error = 0.0
	var hit_count = 0
	for i in tracks:
		if i.ray.is_colliding(): 
			average_error += i.height_error
			hit_count += 1
	average_error /= hit_count
	return average_error

func fetch_if_colliding() -> bool:
	var colliding = false
	for i in tracks:
		if i.ray.is_colliding():
			colliding = true
			break
	return colliding


func _evaluate_los(los_ray: ShapeCast3D) -> bool:

	if los_ray.is_colliding() and los_ray.get_collider(0) == player:
		return true
	return false
