class_name STF_Armature
extends STF_Handler

func _get_stf_type() -> String: return "stf.armature"
func _get_priority() -> int: return 0
func _get_stf_category() -> String: return "data"
func _get_like_types() -> Array[String]: return ["armature"]

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var ret = Skeleton3D.new()
	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Armature")
	var stf_resource := _set_stf_meta(STF_ResourceHelper.new(context, stf_id, json_resource, _get_stf_category()), ret)

	var armature = STF_Armature_Model.new()
	armature.resource_name = ret.name
	armature.set_meta("stf", stf_resource._meta)
	ret.set_meta("stf_resource", armature)

	for child_id in json_resource.get("root_bones", []):
		var bone_index: int = stf_resource.import(child_id, "node", ret, ret)
		armature.root_bones.append(ret.get_bone_meta(bone_index, "stf_resource"))

	for i in range(ret.get_bone_count()):
		armature.bones.append(ret.get_bone_meta(i, "stf_resource"))

	ret.reset_bone_poses()

	return ImportResult.new(ret, null, OptionalCallable.new(func(component_meta):
		#ret.get_meta("stf")["components"].append(component_meta)
		armature.get_meta("stf")["components"].append(component_meta)
	))
