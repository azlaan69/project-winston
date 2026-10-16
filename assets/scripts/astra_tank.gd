extends BaseTank

enum shot { SINGLE, BURST, LONGBURST }
var queued_shot = shot.SINGLE

var dir = Vector3.FORWARD
var speed = 25.0

enum action { RAM, PUNCH, STRAFE }
var queued_action = action.STRAFE

@export var turret: Node3D
@export var los_ray: RayCast3D

@export_group("Particles")
@export var charge_particles: GPUParticles3D
@export var shoot_particles: GPUParticles3D

@export_group("Debug")
@export var debug_label: Label3D

var player_in_cone := false
var shot_eligible := false
var tracking := true
var is_firing := false

var move_timer := 0.0
var bullet_cd := 0.0

var phase_timer := 0.0
var _is_ram_locked := false
var _strafe_side = -1.0

func _physics_process(delta: float) -> void:
	
	move_timer += delta
	bullet_cd = maxf(0.0, bullet_cd - delta)
	
	if move_timer > 5.0: 
		move_timer = 0.0
		reroll_move()
	
	var gun_arrow = -turret.gun.global_transform.basis.z
	var player_arrow = turret.gun.global_position.direction_to(player.global_position)
	player_in_cone = gun_arrow.angle_to(player_arrow) < deg_to_rad(10.0)
	
	shot_eligible = bullet_cd <= 0.0 and player_in_cone and !is_firing
	
	debug_label.text = str(dir, action.find_key(queued_action))
	
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
	
	match queued_action:
		action.RAM:
			ram_process(delta)
		action.STRAFE:
			strafe_process(delta)
		action.PUNCH:
			punch_process(delta)
	
	update_chassis(delta, dir, speed)
	move_and_slide()

func ram_process(delta) -> void:
	
	phase_timer += delta
	
	if phase_timer < 0.8:
		dir = -get_rot_to_player()
		speed = top_speed / 2.0
	
	elif phase_timer < 2.5:
		if not _is_ram_locked: enter_ram()
		speed = top_speed * 2.0
	
	elif phase_timer < 3.5:
		_is_ram_locked = false
		speed = 0.0
	
	else:
		reroll_move()

func strafe_process(delta) -> void:
	
	phase_timer += delta
	
	dir = get_rot_to_player().cross(fetch_normal()) * _strafe_side
	speed = top_speed
	
	if phase_timer > 3.0:
		reroll_move()
	

func punch_process(delta) -> void:
	pass

func enter_ram() -> void:
	dir = get_rot_to_player()
	_is_ram_locked = true

func enter_strafe() -> void:
	if randf() < 0.5:
		_strafe_side = 1.0
	else:
		_strafe_side = -1.0

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
	phase_timer = 0.0
	
	if move_weight < 0.25:
		queued_action = action.RAM
	
	#elif move_weight < 0.5:
		#queued_action = action.PUNCH
	
	elif move_weight < 1.0:
		enter_strafe()
		queued_action = action.STRAFE


func do_nothing() -> void:
	pass
