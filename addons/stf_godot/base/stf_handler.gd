@abstract class_name STF_Handler
extends RefCounted
## Base class for every STF-resource-handler to inherit.
## Provides functionality to import a specific STF resource `type` into a Godot construct and to serialize that Godot construct back into the STF resource
##
## [url]https://docs.stfform.at/format/stf_format.html#resources-object[/url]

## The `type` property on STF resources to match to the stf_handler.
@abstract func _get_stf_type() -> String

## If multiple handlers are registered for the same `type`, then the priority determines the match.
@abstract func _get_priority() -> int

## Can be `data`, `node`, `instance` or `component`. Useful for validation.
@abstract func _get_stf_category() -> String

## I.e. `stf.node` would set `["node"]`. Useful for validation.
@abstract func _get_like_types() -> Array[String]

## Godot type to match for export
@abstract func _get_godot_types() -> Array[String]

## Since Godot types will be ambiguous in many cases, objects will be checked on a case by case basis.
@abstract func _check_godot_object(godot_object: Variant) -> int

## Set true only for export only handlers which handle Godot resources that should not become STF resources, but instead their children should. I.e. `BoneAttachment3D`
func _is_transient() -> bool: return false


## Holds the information needed to convert an STF animation track to a Godot animation track.
class ImportAnimationPropertyResult:
	extends RefCounted

	var _godot_path: String
	var _keyframe_converter: Callable
	var _value_transform_func: OptionalCallable
	var _can_import_bezier: bool

	## [param godot_path] Path to the Node in the scene.[br]
	## [param keyframe_converter] Function which converts an stf keyframe and inserts it into a Godot animation track:
	## [codeblock]
	## func(context: STF_ResourceHelper, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling: int = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true, track_type = Animation.TYPE_VALUE)
	## [/codeblock][br]
	## [param value_transform_func] Optional function that converts an stf keyframes value into Godot values:
	## [codeblock]
	## func(value: Variant) -> Variant
	## [/codeblock][br]
	## [param can_import_bezier] Whether bezier interpolation is supported for this Godot track. I.e. Godot bones do not support bezier.[br]
	func _init(godot_path: String, keyframe_converter: Callable = STFAnimationImportUtil.import_value, value_transform_func: OptionalCallable = null, can_import_bezier = true) -> void:
		self._godot_path = godot_path
		self._keyframe_converter = keyframe_converter
		self._value_transform_func = value_transform_func
		self._can_import_bezier = can_import_bezier

	func valid() -> bool:
		return self._godot_path && self._keyframe_converter


class ImportResult:
	extends RefCounted
	var _godot_object: Variant
	var _property_converter: OptionalCallable ## [code]func(stf_path: Array, godot_object: Object) -> ImportAnimationPropertyResult[/code]
	var _set_component_meta: OptionalCallable ## [code]func(component_meta: Object) -> void[/code]

	## [param godot_object] The resulting Godot object[br]
	## [param property_converter] Optional function to convert stf animations:
	## [codeblock]
	## func(stf_path: Array, godot_object: Object) -> ImportAnimationPropertyResult
	## [/codeblock][br]
	## [param set_component_meta] Optional function to set component meta for a data or node resource:
	## [codeblock]
	## func(component_meta: Object) -> void
	## [/codeblock][br]
	func _init(
		godot_object: Variant = null,
		property_converter: OptionalCallable = null,
		set_component_meta: OptionalCallable = OptionalCallable.new(func(component_meta): if(godot_object is Object && godot_object.has_meta("stf")): godot_object.get_meta("stf")["components"].append(component_meta))
	) -> void:
		self._godot_object = godot_object
		self._property_converter = property_converter
		self._set_component_meta = set_component_meta


func _set_stf_meta(stf_resource: STF_ResourceHelper, godot_object: Object) -> STF_ResourceHelper:
	var stf_kind := _get_stf_category()
	if(_get_stf_category() == "instance"):
		godot_object.set_meta("stf_instance_id", stf_resource._meta["stf_id"])
		godot_object.set_meta("stf_instance", stf_resource._meta)
	else:
		godot_object.set_meta("stf_id", stf_resource._meta["stf_id"])
		godot_object.set_meta("stf", stf_resource._meta)
	return stf_resource


## The main star for import.
@abstract func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult


## Function to run post import.
func _import_post(root: Node) -> void:
	pass


class ExportResult:
	extends RefCounted
	var _stf_id: String
	var _json_resource: Dictionary
	var _components: Array[Variant]
	func _init(stf_id: String, json_resource: Dictionary, components: Array[Variant] = []) -> void:
		self._stf_id = stf_id
		self._json_resource = json_resource
		self._components = components

## The main star for export.
@abstract func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant, instance_context: Variant) -> ExportResult
