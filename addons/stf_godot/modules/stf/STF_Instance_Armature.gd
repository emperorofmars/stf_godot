class_name STF_Instance_Armature
extends STF_Module

func _get_stf_type() -> String:
	return "stf.instance.armature"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "instance"

func _get_like_types() -> Array[String]:
	return ["instance.armature", "instance"]

func _get_godot_type() -> String:
	return "Skeleton3D"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var armature: Skeleton3D = context.import(json_resource["armature"])
	var ret: Skeleton3D = armature.duplicate()

	ret.set_meta("stf_instance_id", stf_id)
	ret.set_meta("stf_instance_name", json_resource.get("name", null))

	# todo pose and stuff

	return armature

func _export() -> STF_ResourceExport:
	return null

