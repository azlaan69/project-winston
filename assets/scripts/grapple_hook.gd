extends Node3D

var start: Vector3
var end: Vector3

func update(new_pos) -> void:
	end = new_pos

func _process(delta: float) -> void:
		
	var imm_mesh = $Mesh.mesh as ImmediateMesh
	if not imm_mesh: return
		
	imm_mesh.clear_surfaces()
	imm_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	imm_mesh.surface_add_vertex(Vector3.ZERO)
	imm_mesh.surface_add_vertex(to_local(end))
	imm_mesh.surface_end()
