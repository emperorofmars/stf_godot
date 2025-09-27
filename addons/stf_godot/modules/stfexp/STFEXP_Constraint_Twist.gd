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
	var parent: STF_Bone.ArmatureBone = context_object

	var ret = CopyTransformModifier3D.new()
	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Twist Constraint " + parent._skeleton.get_bone_name(parent._bone_index))
	parent._skeleton.add_child(ret)

	var target: Array = json_resource.get("target", [])
	var ref_bone: int = -1

	var _handle = func ():
		if(len(target) == 1):
			ref_bone = STF_Godot_Util.get_bone_from_skeleton(parent._skeleton, STF_Godot_Util.get_resource_reference(json_resource, target[0]))
		elif(len(target) == 0):
			var bone_parent: int = parent._skeleton.get_bone_parent(parent._bone_index)
			if(bone_parent < 0): return
			ref_bone = parent._skeleton.get_bone_parent(bone_parent)
		else:
			return

		if(ref_bone < 0): return

		ret.set_setting_count(1)
		ret.set_axis_flags(0, CopyTransformModifier3D.AXIS_FLAG_Y)
		ret.set_copy_flags(0, CopyTransformModifier3D.TRANSFORM_FLAG_POSITION)
		ret.set_reference_bone(0, ref_bone)
		ret.set_apply_bone(0, parent._bone_index)
		ret.set_amount(0, json_resource.get("weight", 0.5))
		ret.set_relative(0, true)
		ret.set_additive(0, true)
	context._add_task(_handle)

	return ImportResult.new(ret)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
