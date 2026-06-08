class_name STF_Material
extends STF_Handler
## STF material.
## Uses [STF_Material_Registry] to select a [STF_Material_Converter] to use for the conversion into a Godot material.
##
## [url]https://docs.stfform.at/resources/stf/stf_material.html[/url]

func _get_stf_type() -> String: return "stf.material"
func _get_priority() -> int: return 0
func _get_stf_category() -> String: return "data"
func _get_like_types() -> Array[String]: return ["material"]
func _get_godot_types() -> Array[String]: return ["BaseMaterial3D"]

func _check_godot_object(godot_object: Variant) -> int:
	return 1 if godot_object is BaseMaterial3D else -1


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var target_shader_name: String = json_resource.get("shader_targets", {}).get("godot", "")
	var style_hints: Array = json_resource.get("style_hints", [])

	var converter = STF_Material_Registry.match_material(target_shader_name, style_hints)
	if(!converter):
		if(context._get_import_options().get(STF_ImportOptions.EnableDebugLog, false)):
			print_rich("[color=orange]STF Warning: Couldn't match Godot material for resource: [b]", stf_id, "[/b], falling back to StandardMaterial3D[/color]")
		converter = StandardMaterial3D_Converter.new()

	return converter._convert(context, stf_id, json_resource, context_object, instance_context)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant, instance_context: Variant) -> ExportResult:
	return null

