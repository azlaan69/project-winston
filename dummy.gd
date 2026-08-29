extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var hp = 100.0
var player = null

var iframe_timer = 0.0

var dir = Vector3.ZERO
@onready var anim = $AnimationPlayer

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	var mesh_node = $MeshInstance3D
	if mesh_node.material_override:
		mesh_node.material_override = mesh_node.material_override.duplicate()
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if player:
		dir = (player.global_position - global_position).normalized()
	
	if iframe_timer > 0.0: iframe_timer -= delta
	
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	
	if hp <= 0:
		die()
	
	move_and_slide()

func hit(hit_data: Dictionary) -> void:
	var dmg: float = float(hit_data.get("damage", 0.0))
	hp -= dmg
	iframe_timer = 0.2
	#anim.play("hit")
	var tween = create_tween()
	tween.tween_property($MeshInstance3D.material_override, "albedo_color", Color.WHITE, 0.05)
	tween.tween_property($MeshInstance3D.material_override, "albedo_color", Color.RED, 0.15)

func die() -> void:
	queue_free()
