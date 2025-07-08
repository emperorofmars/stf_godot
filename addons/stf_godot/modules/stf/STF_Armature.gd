class_name STF_Armature
extends STF_Module

func _get_stf_type() -> String:
	return "stf.armature"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "data"

func _get_like_types() -> Array[String]:
	return ["armature"]

func _get_godot_type() -> String:
	return "Skeleton3D"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var ret = Skeleton3D.new()
	ret.name = json_resource.get("name", "STF Armature")

	ret.set_meta("stf_id", stf_id)
	ret.set_meta("stf_name", json_resource.get("name", null))
	
	for child_id in json_resource.get("root_bones", []):
		context.import(child_id, "node", ret)

	return ret

func _export() -> STF_ResourceExport:
	return null

