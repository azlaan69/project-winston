extends BaseTank

@export var turret: Node3D
@export var los_ray: RayCast3D

@export_group("Particles")
@export var charge_particles: GPUParticles3D
@export var shoot_particles: GPUParticles3D

var los := true
var tracking := true
var bullet_timer := 0.0

func _physics_process(delta: float) -> void:
	bullet_timer += delta
	
	#los = los_ray.is_colliding() and los_ray.get_collider() == player
	
	if bullet_timer > 2.0 and los:
		fire_sequence()
		bullet_timer = 0.0
	
	if tracking:
		turret.apply_tracking(delta)

func fire_sequence(time: float = 0.5) -> void:
	
	charge_particles.restart()
	await charge_particles.finished
	
	shoot_particles.restart()
	
	player.juice.add_trauma(0.5)
	turret.fire()
