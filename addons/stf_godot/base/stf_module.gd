# todo abstract
class_name STF_Module
extends RefCounted
## Base class for every STF module to inherit
## Provides functionality to _import a specific STF resource `type` into a Godot construct and to serialize that Godot construct back into the STF resource

func _get_stf_type() -> String:
	return ""

func _get_priority() -> int:
	return -1

func _get_stf_kind() -> String:
	return ""

func _get_like_types() -> Array[String]:
	return []

func _get_godot_type() -> String:
	return ""

func _check_godot_object(godot_object: Object) -> int:
	return -1

class OptionalCallable:
	extends RefCounted
	var _callable: Callable
	func _init(callable: Callable) -> void: self._callable = callable

class ImportAnimationPropertyResult:
	extends RefCounted
	var _godot_path: String
	var _keyframe_converter: Callable
	var _value_transform_func: OptionalCallable
	func _init(godot_path: String, keyframe_converter: Callable = STFAnimationImportUtil.import_value, value_transform_func: OptionalCallable = null) -> void:
		self._godot_path = godot_path
		self._keyframe_converter = keyframe_converter
		self._value_transform_func = value_transform_func

class ImportResult:
	extends RefCounted
	var _godot_object: Variant
	var _property_converter: OptionalCallable # (stf_path: Array, godot_object: Object) -> ImportAnimationPropertyResult
	func _init(godot_object: Variant, property_converter: OptionalCallable = null) -> void:
		self._godot_object = godot_object
		self._property_converter = property_converter

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	return null

class ExportResult:
	extends RefCounted
	var _stf_id: String
	var _json_resource: Dictionary
	func _init(stf_id: String, json_resource: Dictionary) -> void:
		self._stf_id = stf_id
		self._json_resource = json_resource

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
