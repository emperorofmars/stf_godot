class_name STF_Material
extends STF_Handler
## Uses [STF_Material_Registry] to select a [STF_Material_Converter].

func _get_stf_type() -> String: return "stf.material"
func _get_priority() -> int: return 0
func _get_stf_category() -> String: return "data"
func _get_like_types() -> Array[String]: return ["material"]
func _get_godot_type() -> String: return "BaseMaterial3D"

func _check_godot_object(godot_object: Variant) -> int:
	return 1 if godot_object is BaseMaterial3D else -1


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var converter = STF_Material_Registry.match_material(json_resource)
	return converter._convert(context, stf_id, json_resource, context_object, instance_context)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

