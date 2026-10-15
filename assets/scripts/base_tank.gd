class_name BaseTank
extends CharacterBody3D

var player = null
var tracks: Array[Node] = []

@export var tracks_parent: Node3D
@export var update_rate: float = 20.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	tracks = tracks_parent.get_children()

func update_chassis(delta) -> void:
	var goal_basis = Basis.looking_at(-global_transform.basis.z, fetch_normal())
	global_transform.basis = global_transform.basis.slerp(goal_basis, update_rate * delta)

func fetch_normal() -> Vector3:
	var average_normal = Vector3.ZERO
	for i in tracks:
		if i.ray.is_colliding():
			var normal = i.ray.get_ray_normal()
			average_normal += normal
	average_normal = average_normal.normalized()
	if !average_normal.is_equal_approx(Vector3.ZERO): return average_normal
	else: return Vector3.UP
