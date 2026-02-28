class_name STFEXP_Constraint_IK
extends STF_Module

func _get_stf_type() -> String: return "stfexp.constraint.ik"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "component"
func _get_like_types() -> Array[String]: return ["constraint.ik", "constraint"]
func _get_godot_type() -> String: return "IKModifier3D"

func _check_godot_object(godot_object: Variant) -> int:
	return 1 if godot_object is IKModifier3D else -1 # todo to this properly


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	if(instance_context is not Skeleton3D):
		print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.ik[/u] with ID [u]" + stf_id + "[/u][/color]: Godot IK constraints only support bones.")
		return null
	var armature: Skeleton3D = instance_context
	var bone_index: int = context_object

	return null
	#return ImportResult.new(ret, null)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
