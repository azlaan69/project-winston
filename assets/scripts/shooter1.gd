extends BaseEnemy

enum state { IDLE, CHASE, TELEGRAPH, ATTACK, KICK, RETREAT, REPOSITION, STAGGER }
var current_state = state.IDLE

var telegraph_timer: float
var cooldown: float = 0.0
var movement: Vector3
var los: bool
var shots: int = 0

var strafe: Vector3
var side: float

@export var armhinge: Node3D
@export var head: Node3D
@export var bulletpos: Marker3D
@export var anim: AnimationPlayer
@export var hitanim: AnimationPlayer
const BULLET = preload("res://assets/scenes/enemies/bullet1.tscn")

func _physics_process(delta: float) -> void:
	super(delta)
	update_nav_target()
	aim(delta)
	distance = (player.global_position - global_position)
	
	dir = distance.normalized()
	var dist = distance.length()
	los = check_los()
	#player.debug.text = str(los)
	
	if cooldown > 0.0: cooldown -= delta
	
	match current_state:
		state.IDLE:
			
			rotate_towards(dir, look_speed, delta)
			movement = movement.lerp(Vector3.ZERO, accel * delta)
			anim.play("idle", 0.6)
			
			if dist > 70.0:
				pass
			elif dist < 2.0:
				change_state(state.KICK)
			elif dist < 8.0:
				change_state(state.CHASE)
			elif cooldown <= 0.0 and dist <= 30.0:
				change_state(state.TELEGRAPH)
			elif dist > 30.0:
				change_state(state.CHASE)
				
			
		state.CHASE:
			
			var path_dir = get_next_path_dir(delta) if (!los or dist > 8.0) else dir
			var has_path = path_dir != Vector3.ZERO
			rotate_towards(path_dir, look_speed, delta)
			var target = -transform.basis.z * speed if has_path else Vector3.ZERO
			movement = movement.lerp(target, accel * delta)
			
			if los:
				if dist < 2.0:
					change_state(state.KICK)
				elif dist <= 30.0 and dist > 2.0 and cooldown <= 0.0:
					change_state(state.TELEGRAPH)
			
		state.TELEGRAPH:
			 
			rotate_towards(dir, look_speed * 1.5, delta)
			telegraph_timer -= delta
			if telegraph_timer <= 0.0:
				if los:
					change_state(state.ATTACK)
				else:
					change_state(state.CHASE)
				
		state.ATTACK:
			
			shots += 1
			shoot()
			cooldown = 0.5
			if shots >= 3:
				shots = 0
				change_state(state.REPOSITION)
			else:
				change_state(state.IDLE)
			
		state.KICK:
			rotate_towards(dir, look_speed, delta * 2)
			movement = movement.lerp(Vector3.ZERO, accel * 2 * delta)
		
		state.RETREAT:
			rotate_towards(dir, look_speed, delta)
			var target = -Vector3(dir.x, 0, dir.z).normalized()
			movement = movement.lerp(target * speed * 0.6, accel * delta)
			if cooldown <= 0.0:
				change_state(state.IDLE)
		
		state.REPOSITION:
			rotate_towards(dir, look_speed, delta)
			var flat_dir = Vector3(dir.x, 0, dir.z).normalized()
			strafe = flat_dir.cross(Vector3.UP) * side
			movement = movement.lerp(strafe * speed * 0.6, accel * delta)
			if cooldown <= 0.0: change_state(state.IDLE)
		
		state.STAGGER:
			movement = Vector3.ZERO
			if cooldown <= 0.0: change_state(state.IDLE)

	if movement.length() > 0.0 and current_state in [state.CHASE, state.RETREAT, state.REPOSITION] and iframe_timer <= 0.0:
		anim.play("walk", 0.0, movement.length() / 10)
	
	velocity.x = movement.x
	velocity.z = movement.z
	velocity += kb_velocity
	#$Label3D.text = str(los, state.find_key(current_state))
	
	move_and_slide()

func change_state(new_state: state) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	
	match current_state:
		state.IDLE:
			anim.play("idle")
		state.CHASE, state.RETREAT:
			anim.play("walk")
		state.TELEGRAPH:
			anim.play("idle")
			telegraph_timer = 0.2
		state.KICK:
			cooldown = 2.0
			anim.play("kick")
		state.REPOSITION:
			anim.play("walk")
			side = -1.0 if randf() > 0.5 else 1.0
		state.STAGGER:
			cooldown = 2.0

func aim(delta) -> void:
	var target = (player.global_position + Vector3(0, 1.5, 0)) - armhinge.global_position
	var flat_dist = Vector2(target.x, target.z).length()
	var angle = Vector2(flat_dist, target.y).angle()
	armhinge.rotation.z = lerp_angle(armhinge.rotation.z, angle, 16.0 * delta)
	head.rotation.z = lerp_angle(head.rotation.z, angle, 16.0 * delta)
	
func shoot() -> void:
	var bullet = BULLET.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = bulletpos.global_position
	bullet.global_transform.basis = global_transform.basis.rotated(global_transform.basis.x.normalized(), armhinge.rotation.z)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"kick":
			change_state(state.RETREAT)


func _on_kick_connected(body: Node3D) -> void:
	if body.is_in_group("player"):
		var hit_data: Dictionary = {
		"damage": 20.0,
		"knockback": 20,
		"dir": -transform.basis.z
		}
		body.hit(hit_data)

func hit(hit_data) -> void:
	super(hit_data)
	hitanim.play("hit")
	if hit_data["damage"] >= 2.0: change_state(state.STAGGER)
