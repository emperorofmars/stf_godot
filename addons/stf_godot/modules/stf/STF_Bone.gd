class_name STF_Bone
extends STF_Module

func _get_stf_type() -> String:
	return "stf.bone"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "node"

func _get_like_types() -> Array[String]:
	return ["bone"]

func _get_godot_type() -> String:
	return "Bone"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var armature: Skeleton3D = context_object
	var bone_index := armature.add_bone(json_resource.get("name", stf_id))

	armature.set_bone_meta(bone_index, "stf_id", stf_id)
	armature.set_bone_meta(bone_index, "stf_name", json_resource.get("name", null))
	var stf_meta := {"stf_name": json_resource.get("name", null)}
	armature.set_bone_meta(bone_index, "stf", stf_meta)

	var rest_pose = Transform3D(Basis(STF_TRS_Util.parse_quat(json_resource["rotation"]).normalized()), STF_TRS_Util.parse_vec3(json_resource["translation"]))
	armature.set_bone_rest(bone_index, rest_pose)

	for child_id in json_resource.get("children", []):
		var child_index = context.import(child_id, "node", context_object)
		armature.set_bone_parent(child_index, bone_index)
		armature.set_bone_rest(child_index, rest_pose.inverse() * armature.get_bone_rest(child_index))

	var animation_property_resolve_func = func (stf_path: Array, godot_object: Object):
		if(len(stf_path) < 2): return null
		var node: Skeleton3D = godot_object
		var anim_bone_index = -1
		for i in range(node.get_bone_count()):
			if(node.get_bone_meta(i, "stf_id") == stf_path[0]):
				anim_bone_index = i
				break
		if(anim_bone_index >= 0):
			match stf_path[1]:
				"t": return ImportAnimationPropertyResult.new("bones:" + str(anim_bone_index) + ":position", Animation.TYPE_POSITION_3D) # todo no clue if this is how it works
				"r": return ImportAnimationPropertyResult.new("bones:" + str(anim_bone_index) + ":rotation", Animation.TYPE_ROTATION_3D)
				"s": return ImportAnimationPropertyResult.new("bones:" + str(anim_bone_index) + ":scale", Animation.TYPE_SCALE_3D)
				"components":
					return null # todo
		return null

	return ImportResult.new(bone_index, OptionalCallable.new(animation_property_resolve_func))

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
