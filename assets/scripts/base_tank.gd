extends CharacterBody3D

var player = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func update_chassis(delta) -> void:
	pass
