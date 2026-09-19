extends RigidBody3D

enum state { EQUIPPED, LAUNCHED, RETURN, LANDED }
var current_state = state.EQUIPPED 

var used: bool = false
var can_use: bool = true

@export var ghost: Node3D
@export var ghostmat: StandardMaterial3D

@onready var player = get_node("../Player")
@onready var cd = $CD
@onready var return_timer = $ReturnTimer
@onready var light = $Node3D/CSGCombiner3D/CSGPolygon3D/OmniLight3D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4

func _physics_process(delta: float) -> void:
	if player and current_state == state.EQUIPPED:
		rotation.y = 0
		freeze = true
		$CollisionShape3D.disabled = true
		global_position = player.global_position + Vector3(0, 2, 0)
	
	elif current_state == state.LAUNCHED:
		rotation.y += 30
		$CollisionShape3D.disabled = false
	
	elif current_state == state.RETURN:
		rotation.y += 30
		var dist = (player.global_position - global_position)
		var dir = dist.normalized()
		var speed = maxf(10.0, linear_velocity.length())
		linear_velocity = lerp(linear_velocity, dir * speed, delta * 50.0)
		#if dist.length() < 3.0: reset()
	
	if global_position.y < -35 and global_position.y - player.global_position.y < -20: reset()
	
	if cd.time_left > 0.0: can_use = false
	else: can_use = true
	
	visible = (current_state != state.EQUIPPED)
	light.visible = (current_state != state.EQUIPPED)

func launch(dir: Vector3, speed: float, dur: float) -> void:
	global_position = player.global_position + dir + Vector3(0, 2, 0)
	current_state = state.LAUNCHED
	freeze = false
	$CollisionShape3D.disabled = false
	linear_velocity = dir * speed
	return_timer.start(dur)

func fling() -> void:
	pass

func reset() -> void:
	current_state = state.EQUIPPED
	freeze = true
	$CollisionShape3D.disabled = true
	global_position = player.global_position + Vector3(0, 2, 0)
	used = false
	cd.start()

func _on_body_entered(body: Node) -> void:
	if current_state == state.LAUNCHED and not body.is_in_group("player"):
		current_state = state.LANDED
		freeze = true
		$CollisionShape3D.disabled = true
		if used: 
			await get_tree().create_timer(1.0).timeout
			reset()

#func _on_area_3d_body_entered(body: Node3D) -> void:
	#if current_state == state.LANDED:
		#if (body.is_in_group("player") or body == player):
			#player.grapple__velocity.y = 40.0
		#elif body.has_method("hit"):
			#body.velocity.y *= -1
			#if body.movement: body.movement.y *= -1
		#else:
			#return
		#await get_tree().create_timer(0.2).timeout
		#if current_state == state.LANDED:
			#reset()


func _on_return_timer_timeout() -> void:
	current_state = state.RETURN
