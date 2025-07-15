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
	var armature: Skeleton3D = context.import(json_resource["armature"], "data")
	var ret: Skeleton3D = armature.duplicate(true)
	ret.reset_bone_poses()

	var stf_meta := {"stf_instance_id": stf_id, "stf_instance_name": json_resource.get("name", null)}
	ret.set_meta("stf", stf_meta)

	if("pose" in json_resource):
		for bone_id in json_resource["pose"]:
			var bone_index = -1
			for i in range(ret.get_bone_count()):
				if(ret.get_bone_meta(i, "stf_id") == bone_id):
					bone_index = i
					break
			if(bone_index < 0): continue
			
			var transform = STF_TRS_Util.parse_transform(json_resource["pose"][bone_id])
			ret.set_bone_pose(bone_index, transform)

	# todo instance component, component mods

	return ret

func _export() -> STF_ResourceExport:
	return null

