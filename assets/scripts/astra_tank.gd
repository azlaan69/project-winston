extends BaseTank

enum shot { SINGLE, BURST, LONGBURST }
var queued_shot = shot.SINGLE

var dir = Vector3.FORWARD
var speed = 25.0

enum action { RAM, DASH, STRAFE }
var queued_action = action.DASH
var last_action = action.STRAFE

@export_group("Components")
@export var turret: Node3D
@export var hitpoint: Area3D


@export_group("Raycasts")
@export var los_ray: ShapeCast3D
@export var whisker_left: RayCast3D
@export var whisker_right: RayCast3D


@export_group("Hitboxes")
@export var ram_hitbox: Area3D


@export_group("Particles")
@export var charge_particles: GPUParticles3D
@export var shoot_particles: GPUParticles3D


@export_group("Debug")
@export var debug_label: Label3D

var player_in_cone := false
var shot_eligible := false
var tracking := true
var is_firing := false
var has_los := false

var move_timer := 0.0
var bullet_cd := 0.0

var phase_timer := 0.0
var _is_ram_locked := false
var _strafe_side = -1.0

func _ready() -> void:
	super()
	hitpoint.damage_taken.connect(_on_engine_damaged)
	hitpoint.died.connect(_on_death_trigger)

func _physics_process(delta: float) -> void:

	bullet_cd = maxf(0.0, bullet_cd - delta)
	
	debug_label.text = str(snappedf(fetch_height_error(), 0.05), " ", action.find_key(queued_action))
	
	evaluate_shot_eligible()
	
	if shot_eligible:
		match queued_shot:
			shot.SINGLE:
				fire_sequence()
			shot.BURST:
				fire_sequence_burst(3, 0.5)
			shot.LONGBURST:
				fire_sequence_burst(20, 0.2)
	
	if tracking:
		turret.apply_tracking(delta)
	
	if whisker_left.is_colliding() and whisker_left.get_collider().is_in_group("geometry"):
		_strafe_side = -1.0
		queued_action = action.DASH
	
	if whisker_right.is_colliding() and whisker_right.get_collider().is_in_group("geometry"):
		_strafe_side = 1.0
		queued_action = action.DASH
	
	match queued_action:
		action.RAM:
			ram_process(delta)
		action.STRAFE:
			strafe_process(delta)
		action.DASH:
			dash_process(delta)
	
	update_chassis(delta, dir, speed)
	update_chassis_visual(delta)
	
	move_and_slide()

func evaluate_shot_eligible() -> void:
	los_ray.target_position = to_local(player.global_position) + Vector3(0.0, -1.0, 0.0)
	has_los = _evaluate_los(los_ray)

	var gun_arrow = -turret.gun.global_transform.basis.z
	var player_arrow = turret.gun.global_position.direction_to(player.global_position)
	player_in_cone = gun_arrow.angle_to(player_arrow) < deg_to_rad(10.0)
	
	shot_eligible = bullet_cd <= 0.0 and player_in_cone and !is_firing and has_los


func ram_process(delta) -> void:
	
	phase_timer += delta
	
	if phase_timer < 1.0:
		dir = -get_rot_to_player()
		speed = top_speed / 2.0
	
	elif phase_timer < 1.5:
		ram_hitbox.monitoring = true
		if not _is_ram_locked: enter_ram()
		speed = top_speed * 4.0
	
	elif phase_timer < 4.0:
		ram_hitbox.monitoring = true
		_is_ram_locked = false
		speed = 0.0
	
	else:
		reroll_move()

func strafe_process(delta) -> void:
	
	phase_timer += delta
	
	var bias = 0.15
	var dist = global_position.distance_to(player.global_position)
	
	if dist > 80:
		bias = 1.0
	elif dist < 80 and dist > 30:
		bias = 0.5
	elif dist < 30:
		bias = -0.3
	
	var speed_wave = sin(phase_timer * 3.0)
	var accel_factor = remap(speed_wave, -1.0, 1.0, 0.7, 1.4)
	
	dir = (get_rot_to_player().cross(fetch_normal()) * _strafe_side + get_rot_to_player() * bias).normalized()
	speed = top_speed * accel_factor
	
	if phase_timer > 3.0:
		reroll_move()


func dash_process(delta) -> void:
	
	phase_timer += delta
	
	if phase_timer < 0.5:
		dir = transform.basis.x * -_strafe_side
		speed = top_speed / 2.0
		#update_transform = false
	
	elif phase_timer < 1.0:
		dir = transform.basis.x * _strafe_side
		speed = top_speed * 2.0
	
	elif phase_timer < 2.0:
		speed = 0.0
	
	else:
		#update_transform = true
		reroll_move()

func enter_ram() -> void:
	dir = get_rot_to_player()
	_is_ram_locked = true

func evaluate_side() -> void:
	if randf() > 0.5:
		_strafe_side = -1.0 if randf() > 0.5 else 1.0
	else:
		_strafe_side = -_strafe_side

func fire_sequence() -> void:

	is_firing = true
	charge_particles.restart()
	await charge_particles.finished
	
	fire_juice()
	
	var callable_effect: Callable = do_nothing
	turret.fire(callable_effect)
	
	finish_sequence()


func fire_sequence_burst(count: int = 3, rest: float = 0.5) -> void:

	is_firing = true
	charge_particles.restart()
	await charge_particles.finished
	
	shoot_particles.restart()
	
	var callable_effect: Callable = fire_juice
	var end_effect: Callable = finish_sequence
	turret.fire_burst(callable_effect, end_effect, count, rest)

func fire_juice() -> void:
	
	shoot_particles.restart()
	player.juice.add_trauma(0.5)

func finish_sequence() -> void:
	is_firing = false
	reroll_shot()

func reroll_shot() -> void:
	
	var shot_weight = randf()
	
	if shot_weight <= 0.1:

		bullet_cd = 5.0
		
	elif shot_weight < 0.5:

		queued_shot = shot.SINGLE
		bullet_cd = 1.5
		
	elif shot_weight < 0.8:

		queued_shot = shot.BURST
		bullet_cd = 2.5
		
	elif shot_weight <= 1.0:

		queued_shot = shot.LONGBURST
		bullet_cd = 3.5

func reroll_move() -> void:
	
	var move_weight = randf()
	
	_is_ram_locked = false
	update_transform = true
	ram_hitbox.monitoring = true
	
	phase_timer = 0.0
	
	last_action = queued_action
	
	if move_weight < 0.4:
		queued_action = action.RAM
	
	elif move_weight < 0.7:
		evaluate_side()
		queued_action = action.DASH
	
	elif move_weight < 1.0:
		evaluate_side()
		queued_action = action.STRAFE

	if last_action == queued_action and queued_action == action.STRAFE: reroll_move()

func do_nothing() -> void:
	pass


func _on_track_body_entered(body: Node3D) -> void:
	if body == player:
		var d_vec = player.global_position - global_position
		d_vec.y = 0.0
		d_vec = d_vec.normalized()
		
		d_vec += Vector3.UP * 0.5
		d_vec = d_vec.normalized()
		
		var v_dir = velocity.normalized()
		var kb_dir = (v_dir * 0.6 + d_vec * 0.4).normalized()
		var kb_vel = maxf(velocity.length() / 2, 20.0)
		
		body.add_impulse(kb_vel, kb_dir)


func _on_ram_hitbox_body_entered(body: Node3D) -> void:
	if body == player:
		var kb = velocity.length() / 3
		var kbd = velocity.normalized()
		var dmg = 50.0
		
		var hit_data = {
			"damage": dmg,
			"knockback": kb,
			"dir": kbd 
		}
		
		player.hit(hit_data)


func _on_engine_damaged() -> void:
	pass

func _on_death_trigger() -> void:
	pass
