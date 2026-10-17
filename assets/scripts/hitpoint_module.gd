extends Area3D

@export var parent: Node3D

var player = null

signal damage_taken
signal died

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _on_area_entered(area: Area3D) -> void:
	if area == player.wpn_manager.sword_hitbox:
		damage_taken.emit()
		
