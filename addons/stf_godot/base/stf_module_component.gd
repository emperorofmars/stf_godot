@abstract class_name STF_ModuleComponent
extends STF_Module

func _get_stf_kind() -> String:
	return "component"

class PreImportResult:
	extends RefCounted
	var _success: bool = false
	var _exclusion_group: String
	func _init(json_resource: Dictionary):
		_success = true
		if("exclusion_group" in json_resource): _exclusion_group = json_resource["exclusion_group"]

func _component_pre_import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> PreImportResult:
	return PreImportResult.new(json_resource)
