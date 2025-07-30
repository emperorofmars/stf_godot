class_name STF_Material
extends STF_Module

func _get_stf_type() -> String:
	return "stf.material"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "data"

func _get_like_types() -> Array[String]:
	return ["material"]

func _get_godot_type() -> String:
	return "Material"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	# todo select target material/shader based on best match or user override
	# todo actually implement this properly
	var ret = StandardMaterial3D.new()
	ret.resource_name = json_resource.get("name", "STF Instance Mesh")

	ret.set_meta("stf_id", stf_id)
	var stf_meta := {"stf_name": json_resource.get("name", "STF Material")}
	ret.set_meta("stf", stf_meta)

	return ret

func _export() -> STF_ResourceExport:
	return null

