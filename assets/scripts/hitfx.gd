extends Node3D

@export var lifetime: float = 0.2
var max_lifetime: float

func _ready() -> void:
	max_lifetime = lifetime

func _physics_process(delta: float) -> void:
	if lifetime > 0.0: lifetime -= delta
	if lifetime <= 0.0: queue_free()

	scale.x = lifetime / max_lifetime
	scale.z = scale.x
	scale.y = scale.x
