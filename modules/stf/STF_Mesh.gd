class_name STF_Mesh
extends STF_Module

func _get_stf_type() -> String:
	return "stf.mesh"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "data"

func _get_like_types() -> Array[String]:
	return ["mesh"]

func _get_godot_type() -> String:
	return "Mesh"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var ret = ArrayMesh.new()
	ret.resource_name = json_resource.get("name", "STF Mesh")

	ret.set_meta("stf_id", stf_id)
	ret.set_meta("stf_name", json_resource.get("name", null))

	var buffer_vertices = context.get_buffer(json_resource["vertices"]).to_float32_array()
	var vertices = PackedVector3Array()
	for i in range(len(buffer_vertices) / 3):
		vertices.push_back(Vector3(buffer_vertices[i * 3], buffer_vertices[i * 3 + 1], buffer_vertices[i * 3 + 2]))
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	ret.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return ret

func _export() -> STF_ResourceExport:
	return null

