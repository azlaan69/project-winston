class_name BulletBase
extends Area3D

var max_lifetime: float = 0.0
var dir: Vector3 = Vector3(0, 0, 0)
var parried: bool = false
var init: bool = false
var hit_data: Dictionary = {}
var hit_effect: Callable

@export var speed: float = 30.0
@export var lifetime: float = 5.0
@export var parriable: bool = true
@export var damage: float = 10.0
@export var knockback: int = 10
@export var hitfx: PackedScene
@export var die_on_hit: bool = true

func _ready() -> void:
	max_lifetime = lifetime
	hit_data = {
		"damage": damage,
		"knockback": knockback,
		"dir": -transform.basis.z
	}

func _physics_process(delta: float) -> void:
	if not init:
		dir = -global_transform.basis.z.normalized()
		hit_data["dir"] = dir
		init = true
	
	lifetime -= delta
	if lifetime <= 0.0: queue_free()
	
	global_position += dir * speed * delta
	
	
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		if !parried: return
		else:
			if hitfx:
				var fx = hitfx.instantiate()
				body.add_child(fx)
				fx.global_position = body.global_position + Vector3(0, 1.0, 0) - (body.global_transform.basis.z * 2.0)
			
			hit_data = {
				"damage": damage * 2,
				"knockback": knockback * 3,
				"dir": -transform.basis.z
			}
			body.hit(hit_data)
	elif body.is_in_group("player") and not parried:
		body.hit(hit_data)
	if die_on_hit: queue_free()
	if hit_effect.is_valid(): hit_effect.call()

func deflect(facing: Vector3) -> void:
	var protectionfirst: Array[RID] = [get_rid()]
	dir = PhysUtil.get_target_in_cone(global_position, facing, 80.0, 1.0, protectionfirst)
	hit_data["dir"] = dir
	if dir.length_squared() > 0.001:
		global_transform.basis = Basis.looking_at(dir, Vector3.UP)
	
	speed *= 1.5
	lifetime += max_lifetime
	parried = true
	parriable = false
