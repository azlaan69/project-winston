class_name BaseEnemy
extends CharacterBody3D

@export var hp = 100.0
@export var speed = 5.0
@export var has_gravity = true
@export var use_nav = true

@export var look_speed = 10.0
@export var accel = 20.0
@export var socialdistance = 10.0

var player = null

var iframe_timer = 0.0
var distance = Vector3.ZERO
var dir = distance.normalized()

enum state { IDLE, CHASE, TELEGRAPH, ATTACK, COOLDOWN }
var current_state = state.IDLE

@onready var nav = get_node_or_null("NavigationAgent3D")

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta
	
	if iframe_timer > 0.0: iframe_timer -= delta
	
	if hp <= 0:
		die()

func update_nav_target() -> void:
	if use_nav and nav and player:
		nav.target_position = player.global_position

func get_next_path_dir(delta) -> Vector3:
	if not use_nav or not nav or nav.is_navigation_finished():
		return dir
	var next_pos = nav.get_next_path_position()
	var target_dir = (next_pos - global_position)
	return target_dir.normalized()

func rotate_towards(target: Vector3, turn_speed: float, delta: float) -> void:
	var flat = Vector3(target.x, 0.0, target.z)
	if flat.length_squared() > 0.01:
		var target_rot = Basis.looking_at(flat, Vector3.UP)
		transform.basis = transform.basis.slerp(target_rot, turn_speed * delta)

func hit(hit_data: Dictionary) -> void:
	if iframe_timer > 0.0: return
	var dmg: float = float(hit_data.get("damage", 0.0))
	hp -= dmg
	iframe_timer = 0.2

func die() -> void:
	queue_free()
