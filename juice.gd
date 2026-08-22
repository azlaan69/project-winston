extends Node3D
@export var player: CharacterBody3D
@export var camera: Camera3D

var shift_allowed = true
var end_fov = 90
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if shift_allowed:
		var speed = Vector2(player.velocity.x, player.velocity.z).length()
		end_fov = remap(speed, 7.0, 30.0, 90.0, 110.0)
		end_fov = clamp(end_fov, 90.0, 110.0)
	var interp_speed = 25.0 if end_fov > camera.fov else 6.0
	camera.fov = lerp(camera.fov, end_fov, delta * interp_speed)

func shift(pos: float, fov: float, time: float = 1.0) -> void:
	position.y = pos
	end_fov = fov
	shift_allowed = false
	await get_tree().create_timer(time).timeout
	position.y = 1.7
	end_fov = 90
	shift_allowed = true
