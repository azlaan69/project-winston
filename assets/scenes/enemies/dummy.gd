extends BaseEnemy

var movement: Vector3

func _physics_process(delta: float) -> void:
	super(delta)
	if player:
		distance = (player.global_position - global_position)
		
	dir = distance.normalized()
	
	if distance.length() <= 30.0 and current_state == state.IDLE: current_state = state.CHASE
	elif distance.length() >= 40.0 and current_state == state.CHASE: current_state = state.IDLE
	
	match current_state:
		state.IDLE:
			movement = movement.lerp(Vector3.ZERO, delta)
		state.CHASE:
			var flat_dir = Vector3(dir.x, 0, dir.z).normalized()
			var target_rot = Basis.looking_at(flat_dir, Vector3.UP)
			transform.basis = transform.basis.slerp(target_rot, 16.0 * delta)
			var target_speed = -transform.basis.z * speed
			movement = movement.lerp(target_speed, 10.0 * delta)
	
	velocity.x = movement.x
	velocity.z = movement.z
	
	move_and_slide()
