@abstract class_name STF_ModuleComponent
extends STF_Module

func _get_stf_kind() -> String:
	return "component"

class PreImportResult:
	extends RefCounted
	var _success: bool = false
	var _overrides: Array = []
	func _init(json_resource: Dictionary):
		_success = true
		_overrides = json_resource.get("overrides", [])

func _component_pre_import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> PreImportResult:
	return PreImportResult.new(json_resource)
