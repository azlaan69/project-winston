extends BaseEnemy

var telegraph_timer: float
var cooldown: float
var movement: Vector3
const BULLET = preload("res://assets/scenes/enemies/bullet1.tscn")

func _physics_process(delta: float) -> void:
	super(delta)
	update_nav_target()
	
	distance = (player.global_position - global_position)
		
	dir = distance.normalized()
	
	if cooldown >= 0.0: cooldown -= delta
	
	if distance.length() <= 50.0 and current_state == state.IDLE: current_state = state.CHASE
	elif distance.length() >= 70.0 and current_state == state.CHASE: current_state = state.IDLE
	elif distance.length() <= socialdistance and current_state == state.CHASE and cooldown <= 0.0: 
		current_state = state.TELEGRAPH
		telegraph_timer = 0.5
	
	match current_state:
		state.IDLE:
			movement = movement.lerp(Vector3.ZERO, delta)
		state.CHASE:
			var path_dir = get_next_path_dir(delta)
			var has_path = path_dir != Vector3.ZERO
			rotate_towards(path_dir, look_speed, delta)
			var move_speed = speed if cooldown < 0.0 else speed / 2.0
			var target = -transform.basis.z * move_speed if has_path else Vector3.ZERO
			movement = movement.lerp(target, accel * delta)
		state.TELEGRAPH:
			var path_dir = get_next_path_dir(delta)
			rotate_towards(path_dir, look_speed * 2, delta)
			var target = transform.basis.z * 1.0
			movement = movement.lerp(target, accel * 2 * delta)
			telegraph_timer -= delta
			if telegraph_timer <= 0.0:
				movement = Vector3.ZERO
				current_state = state.ATTACK
		state.ATTACK:
			var bullet = BULLET.instantiate()
			get_parent().add_child(bullet)
			bullet.global_transform.basis = global_transform.basis
			bullet.global_position = global_position
			cooldown = 5.0
			current_state = state.IDLE
	
	velocity.x = movement.x
	velocity.z = movement.z
	
	move_and_slide()
