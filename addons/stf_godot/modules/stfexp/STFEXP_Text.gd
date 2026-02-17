class_name STFEXP_Text
extends STF_Module

class STFEXP_Text_Resource:
	extends Resource
	@export var text: String = ""

func _get_stf_type() -> String: return "stfexp.text"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "data"
func _get_like_types() -> Array[String]: return ["text"]
func _get_godot_type() -> String: return "STFEXP_Text_Resource"

func _check_godot_object(godot_object: Variant) -> int:
	return 1 if godot_object is STFEXP_Text_Resource else -1


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var ret = STFEXP_Text_Resource.new()
	var stf_resource := _set_stf_meta(STF_Resource.new(context, stf_id, json_resource, _get_stf_kind()), ret)

	ret.text = json_resource.get("text")

	return ImportResult.new(ret, null)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

