# todo abstract
class_name STF_Module
extends RefCounted
## Base class for every STF module to inherit
## Provides functionality to _import a specific STF resource `type` into a Godot construct and to serialize that Godot construct back into the STF resource

func _get_stf_type() -> String:
	return ""

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return ""

func _get_like_types() -> Array[String]:
	return []

func _get_godot_type() -> String:
	return ""

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	return null

func _export() -> STF_ResourceExport:
	return null
