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

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
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

	var animation_property_resolve_func = func (stf_path: Array, godot_object: Object):
		if(len(stf_path) < 2): return null
		var node: Skeleton3D = godot_object
		if(len(stf_path) > 1):
			match stf_path[1]:
				"component_mods": return null

			var anim_ret = context.resolve_animation_path(stf_path.slice(1), godot_object)
			if(anim_ret):
				return ImportAnimationPropertyResult.new(node.owner.get_path_to(node).get_concatenated_names() + ":" + anim_ret._godot_path, anim_ret._keyframe_converter)
		return null

	return ImportResult.new(ret, OptionalCallable.new(animation_property_resolve_func))

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

