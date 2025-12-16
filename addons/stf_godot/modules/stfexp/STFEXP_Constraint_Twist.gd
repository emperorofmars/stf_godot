class_name STFEXP_Constraint_Twist
extends STF_Module

func _get_stf_type() -> String: return "stfexp.constraint.twist"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "component"
func _get_like_types() -> Array[String]: return ["constraint.rotation", "constraint"]
func _get_godot_type() -> String: return "CopyTransformModifier3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is CopyTransformModifier3D else -1 # todo to this properly


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	if(context_object is not STF_Bone.ArmatureBone):
		print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.twist[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints are only supported between bones of the same armature.")
		return

	var parent: STF_Bone.ArmatureBone = context_object

	var ret: CopyTransformModifier3D = null
	for child in parent._armature_context._skeleton.get_children():
		if(child is CopyTransformModifier3D):
			ret = child
			break
	if(not ret):
		ret = CopyTransformModifier3D.new()
		ret.name = "STF Constraints"
		parent._armature_context._skeleton.add_child(ret)
		ret.set_meta("stf_composite", [])

	parent._armature_context._add_task(func():
		var source: Array = json_resource.get("source", [])
		var ref_bone: int = -1
		if(len(source) == 1):
			ref_bone = STF_Godot_Util.get_bone_from_skeleton(parent._armature_context._skeleton, STF_Godot_Util.get_resource_reference(json_resource, source[0]))
		elif(len(source) == 0):
			var bone_parent: int = parent._armature_context._skeleton.get_bone_parent(parent._bone_index)
			if(bone_parent < 0):
				print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.twist[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints function only within a single Skeleton3D.")
				return
			ref_bone = parent._armature_context._skeleton.get_bone_parent(bone_parent)
		else:
			print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.twist[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints function only within a single Skeleton3D.")
			return

		if(ref_bone < 0):
			print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.twist[/u] with ID [u]" + stf_id + "[/u][/color]: Invalid source bone.")
			return

		var constraint_index = ret.get_setting_count()
		ret.set_setting_count(constraint_index + 1)
		ret.set_reference_type(constraint_index, CopyTransformModifier3D.REFERENCE_TYPE_BONE)
		ret.set_axis_flags(constraint_index, CopyTransformModifier3D.AXIS_FLAG_Y)
		ret.set_copy_flags(constraint_index, CopyTransformModifier3D.TRANSFORM_FLAG_ROTATION)
		ret.set_reference_bone(constraint_index, ref_bone)
		ret.set_apply_bone(constraint_index, parent._bone_index)
		ret.set_amount(constraint_index, json_resource.get("weight", 0.5))
		ret.set_relative(constraint_index, false)
		ret.set_additive(constraint_index, true)

		ret.get_meta("stf_composite").append({
			"stf_type": _get_stf_type(),
			"stf_id": stf_id,
			"stf_name": json_resource.get("name", null),
			"constraint_index": constraint_index,
		})
	)
	return ImportResult.new(ret, null)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
