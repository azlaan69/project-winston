extends Area3D

@export var parent: Node3D
@export var hp: int = 100.0

var player = null

signal damage_taken
signal died

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func get_damaged(damage: int) -> void:
	hp -= damage

func _on_area_entered(area: Area3D) -> void:
	if area == player.wpn_manager.sword_hitbox:
		damage_taken.emit()
		
