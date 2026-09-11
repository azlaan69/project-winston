@tool
extends Node3D

@export var mask_material: Material:
	set(v): mask_material = v; if v: _apply(self)

func _ready(): if mask_material: _apply(self)

func _apply(n: Node):
	if n is MeshInstance3D: n.material_overlay = mask_material
	for c in n.get_children(): _apply(c)
