extends Node3D
@export var player: CharacterBody3D
@export var camera: Camera3D

var shift_allowed: bool = true
var end_fov: float = 90
var end_tilt: float = 0.0
var end_y: float = 1.7
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if shift_allowed:
		var speed = Vector2(player.velocity.x, player.velocity.z).length()
		end_fov = remap(speed, 0.0, 50.0, 90.0, 110.0)
		end_fov = clamp(end_fov, 90.0, 110.0)
		
		if player.crouching and player.is_on_floor():
			end_y = 1.0
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
			end_tilt = 0.0
	
	var interp_speed = 25.0 if end_fov > camera.fov else 6.0
	camera.fov = lerp(camera.fov, end_fov, delta * interp_speed)
	rotation.z = lerp(rotation.z, end_tilt, delta * 12.0)
	position.y = lerp(position.y, end_y, delta * 12.0)

func shift(pos: float, fov: float, time: float = 1.0, perm: bool = false) -> void:
	position.y = pos
	end_fov = fov
	shift_allowed = false
	if not perm:
		await get_tree().create_timer(time).timeout
		position.y = 1.7
		end_fov = 90
		shift_allowed = true
