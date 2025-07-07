# abstract
class_name STF_Module
extends RefCounted

func get_stf_type() -> String:
	return ""

func get_priority() -> int:
	return 0

func get_stf_kind() -> String:
	return ""

func get_like_types() -> Array[String]:
	return []

func get_godot_type() -> String:
	return ""

func import(context: STF_ImportContext, json_resource: Dictionary, context_object: Variant) -> Variant:
	return null

func export() -> STF_ResourceExport:
	return null
