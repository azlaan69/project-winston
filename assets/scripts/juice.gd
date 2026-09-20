extends Node3D

@export var player: CharacterBody3D
@export var camera: Camera3D
@export var shake: Node3D

var shift_allowed: bool = true
var end_fov: float = 90
var end_tilt: float = 0.0
var end_y: float = 1.7

var trauma: float
var noise = FastNoiseLite.new()
var noise_offset: float = 0.0

var max_offset = Vector3(1.0, 1.0, 1.0)
var max_roll = deg_to_rad(12.0)
var max_pitch = deg_to_rad(15.0)
var max_yaw = deg_to_rad(18.0)
var decay = 3.0
var noise_speed = 350.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	noise.seed = randi()
	noise.frequency = 0.005
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

func _process(delta: float) -> void:
	if shift_allowed:
		var speed = Vector2(player.velocity.x, player.velocity.z).length()
		end_fov = remap(clamp(speed, 0.0, 70.0), 0.0, 30.0, 80.0, 110.0)
		end_fov = clamp(end_fov, 80.0, 110.0)
		
		if player.crouching and player.is_on_floor():
			end_y = 0.8
		else:
			end_y = 1.7
		
		if player.near_wall and not player.is_on_floor():
			end_fov /= 1.15
			if player.wallcheck_l.is_colliding():
				end_tilt = deg_to_rad(-10.0)
			elif player.wallcheck_r.is_colliding():
				end_tilt = deg_to_rad(10.0)
			else:
				end_tilt = 0.0
		else:
			var strafe_input := Input.get_axis("left", "right")
			var strafe_factor = 5.0
			if player.slide_velocity.length() > 2.0 and player.is_on_floor(): strafe_factor = 10.0
			elif player.is_on_floor(): strafe_factor = 5.0
			elif !player.is_on_floor(): strafe_factor = 2.5
			if strafe_input != 0:
				end_tilt = deg_to_rad(strafe_input * strafe_factor)
			else:
				end_tilt = 0.0
				
	noise_speed = lerp(300, 2500, trauma)
	
	if trauma > 0.0:
		trauma = max(trauma - decay * delta, 0.0)
		noise_offset += delta * noise_speed
		apply_shake()
	else:
		camera.h_offset = 0
		shake.position = Vector3.ZERO
		shake.rotation = Vector3.ZERO
	
	var interp_speed = 5.0 if end_fov > camera.fov else 2.0
	camera.fov = lerp(camera.fov, end_fov, 1.0 - exp(delta * -interp_speed))
	rotation.z = lerp(rotation.z, end_tilt, 1.0 - exp(delta * -12.0))
	position.y = lerp(position.y, end_y, 1.0 - exp(delta * -12.0))

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func apply_shake() -> void:
	var amount = pow(trauma, 0.5)
	
	camera.h_offset = max_offset.x * amount * noise.get_noise_2d(noise_offset, 0.0)
	shake.rotation.x = max_pitch * amount * noise.get_noise_2d(noise_offset + 100.0, 0.0)
	shake.rotation.z = max_roll * amount * noise.get_noise_2d(noise_offset + 200.0, 0.0)
	shake.rotation.y = max_yaw * amount * noise.get_noise_2d(noise_offset + 300.0, 0.0)

func shift(pos: float, fov: float, time: float = 1.0, perm: bool = false) -> void:
	if pos != 999.0: position.y = pos
	end_fov = fov
	shift_allowed = false
	if not perm:
		await get_tree().create_timer(time, true, false, true).timeout
		position.y = 1.7
		end_fov = 75
		shift_allowed = true

func shiftend() -> void:
	position.y = 1.7
	end_fov = 75
	shift_allowed = true
