extends RigidBody3D

enum state { EQUIPPED, LAUNCHED, RETURN, LANDED }
var current_state = state.EQUIPPED 

var used: bool = false
var can_use: bool = true
var fly_speed : float = 40.0

@export var ghost: Node3D
@export var ghostmat: StandardMaterial3D

@onready var player = get_node("../Player")
@onready var cd = $CD
@onready var return_timer = $ReturnTimer
@onready var light = $Node3D/CSGCombiner3D/CSGPolygon3D/OmniLight3D
@onready var mesh = $Node3D
@onready var collider = $CollisionShape3D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4

func _physics_process(delta: float) -> void:
	var active = (current_state != state.EQUIPPED)
	visible = active
	light.visible = active
	
	match current_state:
		state.EQUIPPED:
			freeze = true
			collider.disabled = true
			global_position = player.global_position + Vector3(0, 2, 0)
		
		state.LAUNCHED:
			freeze = false
			mesh.rotation.y += 30 * delta
			collider.disabled = false
		
		state.RETURN:
			freeze = false
			mesh.rotation.y += 30 * delta
			collider.disabled = true
			var target_pos = player.global_position + Vector3(0, 1.5, 0)
			var dir_to_player = (target_pos - global_position).normalized()
			linear_velocity = linear_velocity.lerp(dir_to_player * fly_speed, delta * 15.0)
			
			look_at(player.global_position)
			if global_position.distance_to(target_pos) < 2.0: reset()
		
		state.LANDED:
			freeze = true
			collider.disabled = true
			
	if global_position.y < -35.0 and global_position.y - player.global_position.y < -20.0: reset()


func launch(dir: Vector3, speed: float, dur: float) -> void:
	global_position = player.global_position + dir + Vector3(0, 2, 0)
	global_rotation = Vector3.ZERO
	current_state = state.LAUNCHED
	freeze = false
	collider.disabled = false
	linear_velocity = dir * speed
	return_timer.start(dur)

func rebound() -> void:
	current_state = state.RETURN

func fragment() -> void:
	pass

func reset() -> void:
	current_state = state.EQUIPPED
	freeze = true
	$CollisionShape3D.disabled = true
	global_position = player.global_position + Vector3(0, 2, 0)
	used = false
	cd.start()

func _on_body_entered(body: Node) -> void:
	if (current_state == state.LAUNCHED or current_state == state.RETURN) and not body.is_in_group("player"):
		if !body.is_in_group("enemy"):
			current_state = state.LANDED
			freeze = true
			collider.disabled = true
			return_timer.start(2.0)
		elif body.is_in_group("projectile"):
			fragment()
		elif body.is_in_group("enemy"):
			var hit_data = {
				"damage": 5.0,
				"type": "HAT",
				"knockback": 5.0,
				"dir": global_transform.basis.z
			}
			body.hit(hit_data)
			current_state = state.RETURN

func _on_return_timer_timeout() -> void:
	if current_state == state.LAUNCHED or current_state == state.LANDED: current_state = state.RETURN

func _on_cd_timeout() -> void:
	can_use = true
