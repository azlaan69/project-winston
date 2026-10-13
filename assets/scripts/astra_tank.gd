extends BaseTank

@export var turret: Node3D
@export var los_ray: RayCast3D

var los := false
var tracking := true
var bullet_timer := 0.0

func _physics_process(delta: float) -> void:
	bullet_timer += delta
	
	los = los_ray.is_colliding()
	
	if bullet_timer > 2.0 and los:
		fire_sequence()
		bullet_timer = 0.0
	
	if tracking:
		turret.track_predicted(delta)
		turret.track_predicted_gun(delta)

func fire_sequence(time: float = 0.5) -> void:
	tracking = false
	turret.fire()
	await get_tree().create_timer(time).timeout
	tracking = true
