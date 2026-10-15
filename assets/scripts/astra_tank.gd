extends BaseTank

enum shot { SINGLE, BURST, LONGBURST }
var queued_shot = shot.SINGLE

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
var bullet_cd := 0.0

func _physics_process(delta: float) -> void:
	
	bullet_cd = maxf(0.0, bullet_cd - delta)
	var gun_arrow = -turret.gun.global_transform.basis.z
	var player_arrow = turret.gun.global_position.direction_to(player.global_position)
	player_in_cone = gun_arrow.angle_to(player_arrow) < deg_to_rad(10.0)
	
	shot_eligible = bullet_cd <= 0.0 and player_in_cone and !is_firing
	
	debug_label.text = str(shot.find_key(queued_shot))
	
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


func do_nothing() -> void:
	pass
