class_name STFEXP_Constraint_Twist
extends STF_Module

func _get_stf_type() -> String:
	return "stfexp.constraint.twist"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "component"

func _get_like_types() -> Array[String]:
	return ["constraint.rotation", "constraint"]

func _get_godot_type() -> String:
	return "CopyTransformModifier3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is CopyTransformModifier3D else -1 # todo to this properly


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	if(context_object is not STF_Bone.ArmatureBone):
		print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.twist[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints are only supported on bones.")
	var parent: STF_Bone.ArmatureBone = context_object

	var ret = CopyTransformModifier3D.new()
	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Twist Constraint " + parent._armature_context._skeleton.get_bone_name(parent._bone_index))
	parent._armature_context._skeleton.add_child(ret)

	ret.set_meta("stf_id", stf_id)
	var stf_meta := {"stf_name": json_resource.get("name", null)}
	ret.set_meta("stf", stf_meta)

	parent._armature_context._add_task(func():
		var target: Array = json_resource.get("target", [])
		var ref_bone: int = -1
		if(len(target) == 1):
			ref_bone = STF_Godot_Util.get_bone_from_skeleton(parent._armature_context._skeleton, STF_Godot_Util.get_resource_reference(json_resource, target[0]))
		elif(len(target) == 0):
			var bone_parent: int = parent._armature_context._skeleton.get_bone_parent(parent._bone_index)
			if(bone_parent < 0):
				print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.twist[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints function only within a single Skeleton3D.")
				return
			ref_bone = parent._armature_context._skeleton.get_bone_parent(bone_parent)
		else:
			print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.twist[/u] with ID [u]" + stf_id + "[/u][/color]: Godot constraints function only within a single Skeleton3D.")
			return

		if(ref_bone < 0):
			print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.twist[/u] with ID [u]" + stf_id + "[/u][/color]: Invalid target bone.")
			return

		ret.set_setting_count(1)
		ret.set_axis_flags(0, CopyTransformModifier3D.AXIS_FLAG_Y)
		ret.set_copy_flags(0, CopyTransformModifier3D.TRANSFORM_FLAG_ROTATION)
		ret.set_reference_bone(0, ref_bone)
		ret.set_apply_bone(0, parent._bone_index)
		ret.set_amount(0, json_resource.get("weight", 0.5))
		ret.set_relative(0, true)
		ret.set_additive(0, true)
	)

	return ImportResult.new(ret, null)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
