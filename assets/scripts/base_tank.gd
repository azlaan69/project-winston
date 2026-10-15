class_name BaseTank
extends CharacterBody3D

var player = null
var tracks: Array = []

@export var tracks_parent: Node3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	tracks = tracks_parent.get_children()

func update_chassis(delta) -> void:
	pass
