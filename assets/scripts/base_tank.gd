class_name BaseTank
extends CharacterBody3D

var player = null
var tracks: Array[Node] = []
var forward_dir = Vector3.FORWARD

@export var tracks_parent: Node3D
@export var tracking_rate: float = 2.5
@export var steer_rate: float = 5.0
@export var top_speed: float = 25.0
@export var accel: float = 20.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	tracks = tracks_parent.get_children()

func update_chassis(delta, dir: Vector3, speed: float = top_speed) -> void:
	var norm = fetch_normal()
	
	var goal_basis = Basis.looking_at(dir, norm).orthonormalized()
	var clean_current_basis = global_transform.basis.orthonormalized()
	global_transform.basis = clean_current_basis.slerp(goal_basis, tracking_rate * delta)
	
	var target_velocity = dir * speed
	velocity = velocity.lerp(target_velocity, steer_rate * delta)

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
