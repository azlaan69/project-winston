extends RigidBody3D

enum state { EQUIPPED, LAUNCHED, LANDED }
var current_state = state.EQUIPPED 

var used: bool = false
var can_use: bool = true

@onready var player = get_node("../ProtoController")
@onready var cd = $CD

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4

func _physics_process(delta: float) -> void:
	if player and current_state == state.EQUIPPED:
		rotation.y = 0
		freeze = true
		$CollisionShape3D.disabled = true
		global_position = player.global_position + Vector3(0, 2, 0)
	
	elif current_state == state.LAUNCHED: rotation.y += 30
	
	if (global_position.y - player.global_position.y < -20): reset()
	
	if cd.time_left > 0.0: can_use = false
	else: can_use = true
	
	visible = (current_state != state.EQUIPPED)
	$CSGCombiner3D/CSGPolygon3D/OmniLight3D.visible = (current_state != state.EQUIPPED)

func launch(dir: Vector3, speed: float) -> void:
	print(dir)
	global_position = player.global_position + dir + Vector3(0, 2, 0)
	current_state = state.LAUNCHED
	freeze = false
	$CollisionShape3D.disabled = false
	linear_velocity = dir * speed

func fling() -> void:
	pass

func reset() -> void:
	current_state = state.EQUIPPED
	freeze = true
	$CollisionShape3D.disabled = true
	global_position = player.global_position + Vector3(0, 2, 0)
	used = false
	player.can_move = true
	cd.start()

func _on_body_entered(body: Node) -> void:
	if current_state == state.LAUNCHED and not body.is_in_group("player"):
		current_state = state.LANDED
		freeze = true
		$CollisionShape3D.disabled = true
		if used: reset()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if current_state == state.LANDED and (body.is_in_group("player") or body == player):
		player.velocity.y = 20.0
		get_tree().create_timer(0.2).timeout.connect(func(): reset())
