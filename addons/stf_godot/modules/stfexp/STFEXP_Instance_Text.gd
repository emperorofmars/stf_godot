class_name STFEXP_Instance_Text
extends STF_Module

func _get_stf_type() -> String: return "stfexp.instance.text"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "instance"
func _get_like_types() -> Array[String]: return ["instance.text"]
func _get_godot_type() -> String: return "Label3D"

func _check_godot_object(godot_object: Variant) -> int:
	return 1 if godot_object is Label3D else -1


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var ret := Label3D.new()
	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Instance Text")

	var stf_resource := _set_stf_meta(STF_Resource.new(context, stf_id, json_resource, _get_stf_kind()), ret)

	var text_id := STF_Godot_Util.get_resource_reference(json_resource, json_resource["text"])
	var text_resource = context.import(text_id, "data")
	ret.text = text_resource.text

	stf_resource.register_referenced_resource(text_id, text_resource)

	return ImportResult.new(ret, null)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

