class_name STFEXP_Constraint_Twist
extends STF_ModuleComponent

func _get_stf_type() -> String: return "stfexp.constraint.twist"
func _get_priority() -> int: return 0
func _get_like_types() -> Array[String]: return ["constraint.rotation", "constraint"]
func _get_godot_type() -> String: return "CopyTransformModifier3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is CopyTransformModifier3D else -1 # todo to this properly

func _component_pre_import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> PreImportResult:
	if(context_object is not Skeleton3D):
		print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.twist[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints only support bones as targets.")
		return null
	return PreImportResult.new(json_resource)

func __create_finalize_source_func(constraint_holder: CopyTransformModifier3D, bone_index: int, stf_id: String, json_resource: Dictionary, is_instance_mod: bool = false) -> Callable:
	return func(ref_type: int, reference: Variant, context: Variant):
		var constraint_index = constraint_holder.get_setting_count()
		constraint_holder.set_setting_count(constraint_index + 1)
		constraint_holder.set_axis_flags(constraint_index, CopyTransformModifier3D.AXIS_FLAG_Y)
		constraint_holder.set_copy_flags(constraint_index, CopyTransformModifier3D.TRANSFORM_FLAG_ROTATION)
		constraint_holder.set_reference_type(constraint_index, ref_type)
		if(ref_type == CopyTransformModifier3D.REFERENCE_TYPE_BONE):
			constraint_holder.set_reference_bone(constraint_index, reference)
		else:
			constraint_holder.set_reference_node(constraint_index, reference)
		constraint_holder.set_apply_bone(constraint_index, bone_index)
		constraint_holder.set_amount(constraint_index, json_resource.get("weight", 0.5))
		constraint_holder.set_relative(constraint_index, false)
		constraint_holder.set_additive(constraint_index, true)

		constraint_holder.get_meta("stf_composite").append({
			"stf_type": _get_stf_type(),
			"stf_id": stf_id,
			"stf_name": json_resource.get("name", null),
			"is_instance_mod": is_instance_mod,
			"constraint_indices": [constraint_index],
		})


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	if(instance_context is not Skeleton3D):
		print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.twist[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints only support bones as targets.")
		return null
	var armature: Skeleton3D = instance_context
	var bone_index: int = context_object

	var ret := BoneAttachmentUtil.ensure_copy_transform_modifier(armature)
	var finalize_source_func := __create_finalize_source_func(ret, context_object, stf_id, json_resource)
	var error_message = "[color=orange]Warning: Can't import resource [u]" + _get_stf_type() + "[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints can't represent this STF constraint"

	NodepathUtils.handle_stf_source(context, ret, armature, bone_index, json_resource, json_resource.get("source", []), error_message, finalize_source_func)

	return ImportResult.new(ret, null)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
