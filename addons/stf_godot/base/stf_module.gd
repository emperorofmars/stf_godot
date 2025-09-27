@abstract class_name STF_Module
extends RefCounted
## Base class for every STF module to inherit
## Provides functionality to _import a specific STF resource `type` into a Godot construct and to serialize that Godot construct back into the STF resource

## The `type` property on STF resources to match to the stf_module.
@abstract func _get_stf_type() -> String

## If multiple modules are registered for the same `type`, then the priority determines the match.
@abstract func _get_priority() -> int

## Can be `data`, `node`, `component`. Useful for validation.
@abstract func _get_stf_kind() -> String

## I.e. `stf.node` would set `node`. Useful for validation.
@abstract func _get_like_types() -> Array[String]

## Godot type to match for export
@abstract func _get_godot_type() -> String

## Since Godot types will be ambiguous in many cases, objects will be checked on a case by case basis.
@abstract func _check_godot_object(godot_object: Object) -> int


class ImportAnimationPropertyResult:
	extends RefCounted
	var _godot_path: String
	var _keyframe_converter: Callable
	var _value_transform_func: OptionalCallable
	var _can_import_bezier: bool
	func _init(godot_path: String, keyframe_converter: Callable = STFAnimationImportUtil.import_value, value_transform_func: OptionalCallable = null, can_import_bezier = true) -> void:
		self._godot_path = godot_path
		self._keyframe_converter = keyframe_converter
		self._value_transform_func = value_transform_func
		self._can_import_bezier = can_import_bezier

class ImportResult:
	extends RefCounted
	var _godot_object: Variant
	var _property_converter: OptionalCallable # (stf_path: Array, godot_object: Object) -> ImportAnimationPropertyResult
	func _init(godot_object: Variant = null, property_converter: OptionalCallable = null) -> void:
		self._godot_object = godot_object
		self._property_converter = property_converter

## The main star for import.
@abstract func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult


class ExportResult:
	extends RefCounted
	var _stf_id: String
	var _json_resource: Dictionary
	func _init(stf_id: String, json_resource: Dictionary) -> void:
		self._stf_id = stf_id
		self._json_resource = json_resource

## The main star for export.
@abstract func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult
