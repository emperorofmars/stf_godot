class_name STF_Bone
extends STF_Handler

func _get_stf_type() -> String: return "stf.bone"
func _get_priority() -> int: return 0
func _get_stf_category() -> String: return "node"
func _get_like_types() -> Array[String]: return ["bone"]
func _get_godot_types() -> Array[String]: return ["Bone"] # todo this is wrong

func _check_godot_object(godot_object: Variant) -> int:
	return 1 if godot_object is Skeleton3D else -1 # todo this is wrong, devise a way to check for bones


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var armature: Skeleton3D = instance_context
	var bone_name = STF_Godot_Util.get_name_or_default(json_resource, stf_id)
	var bone_index := armature.add_bone(bone_name)

	armature.set_bone_meta(bone_index, "stf_id", stf_id)
	var stf_resource := STF_ResourceHelper.new(context, stf_id, json_resource, _get_stf_category())
	armature.set_bone_meta(bone_index, "stf", stf_resource._meta)

	var rest_pose := Transform3D(Basis(STF_TRS_Util.parse_quat(json_resource["rotation"]).normalized()), STF_TRS_Util.parse_vec3(json_resource["translation"]))
	armature.set_bone_rest(bone_index, rest_pose)

	var stf_bone = STF_Bone_Model.new()
	stf_bone.resource_name = bone_name
	stf_bone._bone_index = bone_index
	stf_bone.set_meta("stf", stf_resource._meta)
	if("translation" in json_resource): stf_bone.translation = STF_TRS_Util.parse_vec3(json_resource["translation"])
	if("rotation" in json_resource): stf_bone.rotation = STF_TRS_Util.parse_quat(json_resource["rotation"]).normalized()
	if("length" in json_resource): stf_bone.length = json_resource["length"]
	if("connected" in json_resource): stf_bone.connected = json_resource["connected"]
	if("deform" in json_resource): stf_bone.deform = json_resource["deform"]
	if("non_deform_use" in json_resource): stf_bone.non_deform_use = json_resource["non_deform_use"]
	armature.set_bone_meta(bone_index, "stf_resource", stf_bone)

	if(
		"deform" in json_resource
		and !json_resource["deform"]
		and "non_deform_use" in json_resource
		and json_resource["non_deform_use"] in ["ik_target", "ik_pole"]
	):
		var ik_node = BoneAttachmentUtil.ensure_attachment(armature, bone_index)
		ik_node.name = STF_Godot_Util.get_name_or_default(json_resource, stf_id)
		#ik_node.override_pose = true # todo convert animations to target the attachment
		armature.set_bone_meta(bone_index, "stf_ik_node", armature.get_path_to(ik_node))


	for child_id in json_resource.get("children", []):
		var child_index: int = stf_resource.import(child_id, "node", context_object, instance_context)
		armature.set_bone_parent(child_index, bone_index)
		armature.set_bone_rest(child_index, rest_pose.inverse() * armature.get_bone_rest(child_index))

		stf_bone.children.append(armature.get_bone_meta(child_index, "stf_resource"))


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
				"t": return ImportAnimationPropertyResult.new(":" + node.get_bone_name(anim_bone_index), STFAnimationImportUtil.import_position_3d, null, false)
				"r": return ImportAnimationPropertyResult.new(":" + node.get_bone_name(anim_bone_index), STFAnimationImportUtil.import_rotation_3d, null, false)
				"r_euler": return ImportAnimationPropertyResult.new(":" + node.get_bone_name(anim_bone_index), STFAnimationImportUtil.import_euler_rotation_3d, null, false)
				"s": return ImportAnimationPropertyResult.new(":" + node.get_bone_name(anim_bone_index), STFAnimationImportUtil.import_scale_3d, null, false)
				"components", "component_mods":
					var anim_ret := context.resolve_animation_path(stf_path.slice(2))
					if(anim_ret):
						return ImportAnimationPropertyResult.new(anim_ret._godot_path, anim_ret._keyframe_converter, anim_ret._value_transform_func, anim_ret._can_import_bezier)
		return null

	return ImportResult.new(bone_index, OptionalCallable.new(animation_property_resolve_func), OptionalCallable.new(func(component_meta):
		#armature.get_bone_meta(bone_index, "stf")["components"].append(component_meta)
		stf_bone.get_meta("stf")["components"].append(component_meta)
	))


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant, instance_context: Variant) -> ExportResult:
	return null
