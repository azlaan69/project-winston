extends Area3D

@export var speed: float = 30.0
@export var lifetime: float = 20.0
@export var hit_data: Dictionary = {
	"damage": 10.0,
	"knockback": Vector3(1, 0, 1)
}

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0: queue_free()
	global_position += -transform.basis.z * speed * delta
	$MeshInstance3D.rotate(Vector3.LEFT, 0.01)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.hit(hit_data)
