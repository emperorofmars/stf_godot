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

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var ret = Skeleton3D.new()
	ret.name = json_resource.get("name", "STF Armature")

	ret.set_meta("stf_id", stf_id)
	var stf_meta := {"stf_name": json_resource.get("name", null)}
	ret.set_meta("stf", stf_meta)

	for child_id in json_resource.get("root_bones", []):
		context.import(child_id, "node", ret)

	ret.reset_bone_poses()

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

