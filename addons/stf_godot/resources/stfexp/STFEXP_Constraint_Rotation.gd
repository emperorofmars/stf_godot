class_name STFEXP_Constraint_Rotation
extends STF_Handler

func _get_stf_type() -> String: return "stfexp.constraint.rotation"
func _get_priority() -> int: return 0
func _get_stf_category() -> String: return "component"
func _get_like_types() -> Array[String]: return ["constraint.rotation", "constraint"]
func _get_godot_types() -> Array[String]: return ["CopyTransformModifier3D"]

func _check_godot_object(godot_object: Variant) -> int:
	return 1000 if godot_object is CopyTransformModifier3D else -1 # todo to this properly


func __create_finalize_source_func(ret: CopyTransformModifier3D, bone_index: int, stf_id: String, json_resource: Dictionary, constraint_indices: Array, axes: int) -> Callable:
	return func(ref_type: int, reference: Variant, handle_context: Variant):
		var constraint_index = ret.get_setting_count()
		ret.set_setting_count(constraint_index + 1)
		constraint_indices.append(constraint_index)
		ret.set_axis_flags(constraint_index, axes)
		ret.set_copy_flags(constraint_index, CopyTransformModifier3D.TRANSFORM_FLAG_ROTATION)
		ret.set_reference_type(constraint_index, ref_type)
		if(ref_type == CopyTransformModifier3D.REFERENCE_TYPE_BONE):
			ret.set_reference_bone(constraint_index, reference)
			ret.set_relative(constraint_index, true)
		else:
			ret.set_reference_node(constraint_index, reference)
		ret.set_apply_bone(constraint_index, bone_index)
		ret.set_amount(constraint_index, handle_context)
		ret.set_additive(constraint_index, true)


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	if(instance_context is not Skeleton3D):
		print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.rotation[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints only support bones as targets.")
		return null

	var armature: Skeleton3D = instance_context
	var bone_index: int = context_object

	#var ret := BoneAttachmentUtil.ensure_copy_transform_modifier(armature)
	var ret: = CopyTransformModifier3D.new()
	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Constraint Rotation - " + armature.get_bone_name(bone_index))
	armature.add_child(ret)
	ret.set_meta("stf_composite", [])

	var constraint_indices = []
	var total_weight = json_resource.get("weight", 1)

	var json_axes: Array = json_resource.get("axes", [true, true, true])
	var axes = 0
	if(json_axes[0] == true): axes |= CopyTransformModifier3D.AXIS_FLAG_X
	if(json_axes[1] == true): axes |= CopyTransformModifier3D.AXIS_FLAG_Y
	if(json_axes[2] == true): axes |= CopyTransformModifier3D.AXIS_FLAG_Z

	var error_message = "[color=orange]Warning: Can't import resource [u]" + _get_stf_type() + "[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints can't represent this STF constraint"

	var finalize_source_func := __create_finalize_source_func(ret, bone_index, stf_id, json_resource, constraint_indices, axes)

	for json_source in json_resource.get("sources", []):
		NodepathUtils.handle_stf_source(context, ret, armature, bone_index, json_resource, json_source.get("source", []), error_message, finalize_source_func, json_source.get("weight", 0.5) * total_weight)

	ret.get_meta("stf_composite").append({
		"stf_type": _get_stf_type(),
		"stf_id": stf_id,
		"stf_name": json_resource.get("name", null),
		"constraint_indices": constraint_indices,
	})

	var animation_property_resolve_func := func(stf_path: Array, godot_object: Object):
		if(len(stf_path) < 2): return null
		var node: CopyTransformModifier3D = godot_object
		var path = armature.get_path_to(node).get_concatenated_names()

		match stf_path[1]:
			"enabled": return ImportAnimationPropertyResult.new("/" + path + ":active")
		# todo weight per source
		return null

	return ImportResult.new(ret, OptionalCallable.new(animation_property_resolve_func))


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant, instance_context: Variant) -> ExportResult:
	return null

