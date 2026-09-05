extends BaseEnemy

var telegraph_timer: float
var cooldown: float = 0.0
var movement: Vector3
var los: bool

@export var armhinge: Node3D
@export var bulletpos: Marker3D
const BULLET = preload("res://assets/scenes/enemies/bullet1.tscn")

func _physics_process(delta: float) -> void:
	super(delta)
	update_nav_target()
	aim(delta)
	distance = (player.global_position - global_position)
	
	dir = distance.normalized()
	var dist = distance.length()
	los = check_los()
	
	if cooldown > 0.0: cooldown -= delta
	
	if current_state != state.TELEGRAPH and current_state != state.ATTACK:
		if not los:
			current_state = state.CHASE
		else:
			if dist > 30.0:
				current_state = state.CHASE
			elif dist < 10.0:
				current_state = state.IDLE
			else:
				if cooldown <= 0.0 and los:
					current_state = state.TELEGRAPH
					telegraph_timer = 0.5
				else:
					current_state = state.IDLE
	
	match current_state:
		state.IDLE:
			movement = movement.lerp(Vector3.ZERO, accel * delta)
		state.CHASE:
			var path_dir = get_next_path_dir(delta)
			var has_path = path_dir != Vector3.ZERO
			rotate_towards(path_dir, look_speed, delta)
			var move_speed = speed
			var target = -transform.basis.z * move_speed if has_path else Vector3.ZERO
			movement = movement.lerp(target, accel * delta)
		state.TELEGRAPH:
			var path_dir = get_next_path_dir(delta)
			rotate_towards(path_dir, look_speed * 2, delta)
			telegraph_timer -= delta
			if telegraph_timer <= 0.0:
				movement = Vector3.ZERO
				current_state = state.ATTACK
		state.ATTACK:
			var bullet = BULLET.instantiate()
			get_parent().add_child(bullet)
			bullet.global_position = bulletpos.global_position
			bullet.global_transform.basis = global_transform.basis.rotated(global_transform.basis.x.normalized(), armhinge.rotation.z)
			cooldown = 1.0
			current_state = state.IDLE
	
	velocity.x = movement.x
	velocity.z = movement.z
	
	move_and_slide()
	
func aim(delta) -> void:
	var target = (player.global_position + Vector3(0, 1.5, 0)) - armhinge.global_position
	var flat_dist = Vector2(target.x, target.z).length()
	var angle = Vector2(flat_dist, target.y).angle()
	armhinge.rotation.z = lerp_angle(armhinge.rotation.z, angle, 16.0 * delta)
	
