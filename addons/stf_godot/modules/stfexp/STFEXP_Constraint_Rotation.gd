class_name STFEXP_Constraint_Rotation
extends STF_Module

func _get_stf_type() -> String: return "stfexp.constraint.rotation"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "component"
func _get_like_types() -> Array[String]: return ["constraint.rotation", "constraint"]
func _get_godot_type() -> String: return "CopyTransformModifier3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is CopyTransformModifier3D else -1 # todo to this properly


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	if(context_object is not STF_Bone.ArmatureBone):
		print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.rotation[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints only support bones as targets.")
		return

	var target: STF_Bone.ArmatureBone = context_object

	var ret := BoneAttachmentUtil.ensure_copy_transform_modifier(target._armature_context._skeleton)
	print(ret, " : ", ret.get_setting_count())

	var constraint_indices = []
	var total_weight = json_resource.get("weight", 1)

	var json_axes: Array = json_resource.get("axes", [true, true, true])
	var axes = 0
	if(json_axes[0] == true): axes |= CopyTransformModifier3D.AXIS_FLAG_X
	if(json_axes[1] == true): axes |= CopyTransformModifier3D.AXIS_FLAG_Y
	if(json_axes[2] == true): axes |= CopyTransformModifier3D.AXIS_FLAG_Z

	var error_message = "[color=orange]Warning: Can't import resource [u]" + _get_stf_type() + "[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints can't represent this STF constraint"

	var finalize_source_func := func(ref_type: int, reference: Variant, handle_context: Variant):
		var constraint_index = ret.get_setting_count()
		ret.set_setting_count(constraint_index + 1)
		constraint_indices.append(constraint_index)
		ret.set_axis_flags(constraint_index, axes)
		ret.set_copy_flags(constraint_index, CopyTransformModifier3D.TRANSFORM_FLAG_ROTATION)
		ret.set_reference_type(constraint_index, ref_type)
		if(ref_type == CopyTransformModifier3D.REFERENCE_TYPE_BONE):
			ret.set_reference_bone(constraint_index, reference)
		else:
			ret.set_reference_node(constraint_index, reference)
		ret.set_apply_bone(constraint_index, target._bone_index)
		ret.set_amount(constraint_index, handle_context * total_weight)
		ret.set_relative(constraint_index, true)
		ret.set_additive(constraint_index, true)

		print(constraint_index, ": ", target._armature_context._skeleton.get_bone_name(ret.get_apply_bone(constraint_index)), " - ", target._armature_context._skeleton.get_bone_name(reference))

	target._armature_context._add_task(func():
		for json_source in json_resource.get("sources", []):
			NodepathUtils.handle_stf_source(context, target, json_resource, json_source.get("source", []), error_message, finalize_source_func, json_source.get("weight", 0.5))
	)

	ret.get_meta("stf_composite").append({
		"stf_type": _get_stf_type(),
		"stf_id": stf_id,
		"stf_name": json_resource.get("name", null),
		"constraint_indices": constraint_indices,
	})
	return ImportResult.new(ret, null)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
