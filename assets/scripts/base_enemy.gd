class_name BaseEnemy
extends CharacterBody3D

@export var hp = 100.0
@export var speed = 5.0
@export var has_gravity = true

var player = null

var iframe_timer = 0.0
var distance = Vector3.ZERO
var dir = distance.normalized()

enum state { IDLE, CHASE, TELEGRAPH, ATTACK, COOLDOWN }
var current_state = state.IDLE

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta
	
	if iframe_timer > 0.0: iframe_timer -= delta
	
	if hp <= 0:
		die()
	
	move_and_slide()

func hit(hit_data: Dictionary) -> void:
	if iframe_timer > 0.0: return
	var dmg: float = float(hit_data.get("damage", 0.0))
	hp -= dmg
	iframe_timer = 0.2

func die() -> void:
	queue_free()
