extends Area3D

var max_lifetime: float = 0.0
var dir: Vector3 = Vector3(0, 0, 0)
var parried: bool = false
var init: bool = false
@export var speed: float = 30.0
@export var lifetime: float = 5.0
@export var parriable: bool = true
@export var hit_data: Dictionary = {
	"damage": 10.0,
	"knockback": 10,
	"dir": -transform.basis.z
}

func _ready() -> void:
	max_lifetime = lifetime

func _physics_process(delta: float) -> void:
	if not init:
		dir = -global_transform.basis.z.normalized()
		hit_data["dir"] = dir
		init = true
	
	lifetime -= delta
	if lifetime <= 0.0: queue_free()
	
	global_position += dir * speed * delta
	$MeshInstance3D.rotation.z += 45 * delta
	
	var fade = clamp(lifetime / max_lifetime, 0.0, 1.0)
	$MeshInstance3D.material_override.emission_energy_multiplier = pow(fade, 5.0)
	
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		if !parried: return
		else:
			hit_data = {
				"damage": 5.0,
				"knockback": 10,
				"dir": -transform.basis.z
			}
			body.hit(hit_data)
	elif body.is_in_group("player") and not parried:
		body.hit(hit_data)
	queue_free()

func deflect(facing: Vector3) -> void:
	var protectionfirst: Array[RID] = [get_rid()]
	var final_dir = PhysUtil.get_target_in_cone(global_position, facing, 80.0, 5.0, protectionfirst)
	dir = final_dir
	hit_data["dir"] = dir
	if dir.length_squared() > 0.001:
		global_transform.basis = Basis.looking_at(dir, Vector3.UP)
	
	speed *= 1.5
	lifetime += max_lifetime
	parried = true
	parriable = false
