extends Node3D

var anim = "pistol"
@onready var sprite = $AnimatedSprite3D

func _ready() -> void:
	await get_tree().process_frame
	if anim == "sword": sprite.material_override = null
	sprite.play(anim)

func _physics_process(delta: float) -> void:
	
	if !sprite.is_playing(): queue_free()
