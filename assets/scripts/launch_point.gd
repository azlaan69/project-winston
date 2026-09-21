extends Area3D

var cooldown = 0.0

func _physics_process(delta: float) -> void:
	if cooldown > 0.0: cooldown -= delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and cooldown <= 0.0:
		var launchdir = global_transform.basis.y.normalized()
		body.kb_add(50.0, launchdir)
		body.grav_velocity = Vector3.ZERO
		cooldown = 0.1
