class_name AVA_SecondaryMotion
extends STF_ModuleComponent

func _get_stf_type() -> String: return "ava.secondary_motion"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "component"
func _get_like_types() -> Array[String]: return ["secondary_motion"]
func _get_godot_type() -> String: return "SpringBoneSimulator3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is SpringBoneSimulator3D else -1 # todo to this properly

func _component_pre_import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> PreImportResult:
	if(instance_context is not Skeleton3D):
		print_rich("[color=orange]Warning: Can't import resource [u]ava.secondary_motion[/u] with ID [u]" + stf_id + "[/u][/color]: Godot only support bones as targets.")
		return null
	return PreImportResult.new(json_resource)

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var armature: Skeleton3D = instance_context
	var bone_index: int = context_object

	var ret := BoneAttachmentUtil.ensure_spring_bone_simulator(armature)

	var setting_index = ret.get_setting_count()
	ret.set_setting_count(setting_index + 1)
	ret.set_root_bone(setting_index, bone_index)

	ret.get_meta("stf_composite").append({
		"stf_type": _get_stf_type(),
		"stf_id": stf_id,
		"stf_name": json_resource.get("name", null),
		"setting_index": setting_index,
	})
	return ImportResult.new(ret, null)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

