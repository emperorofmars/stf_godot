class_name STF_ImportState
extends RefCounted
## Parse an STF_File into Godot constructs


var _stf_file: STF_File
var _modules: Dictionary[String, STF_Module]

var _meta: STF_Info

# STF ID -> Godot Thingy
var _imported_resources: Dictionary[String, Variant] = {}

# func (stf_path: Array, godot_object: Object):
#	return AnimationPropertyResult.new("foo", Animation.TYPE_BEZIER)
var _animation_converters: Dictionary[String, Callable] = {}

var _import_options: Dictionary

# IDs of components that should be ignored
#var _overrides: Array[String] = []

# Group Name -> Dictionary[STF_Type, Array[STF_ID]]
var _exclusion_groups: Dictionary[String, Dictionary] = {}
# Group Name -> Array[STF_Type]
var _exclusion_winners: Dictionary[String, Array] = {}
var _excluded_ids: Array[String] = []

# Array of tasks that can be run for each instance of a resource (i.e. components of an armature or its bones)
#	Dictionary[resource: Variant, Array[Callable[[resource_instance: Variant], null]]]
var _component_instance_context: Dictionary[Variant, Array] = {}

# Dictionary[resource_instance: Variant, Dictionary[component_id: String, json_mod: Dictionary]]
var _component_instance_mods: Dictionary[Variant, Dictionary] = {}


func _init(stf_file: STF_File, modules: Dictionary[String, STF_Module], import_options: Dictionary = {}) -> void:
	_stf_file = stf_file
	_modules = modules
	_meta = STF_Info.parse(_stf_file.json_definition)
	_import_options = import_options


func get_json_resource(stf_id: String) -> Dictionary:
	return _stf_file.json_definition["resources"][stf_id]


func determine_module(json_resource: Dictionary, expected_kind: String = "data") -> STF_Module:
	if(json_resource["type"] in _modules):
		return _modules[json_resource["type"]]
	else:
		if(_import_options.get("enable_debug_log", false)):
			print_rich("[color=orange]STF Warning: Unrecognized resource: [b]", json_resource["type"], "[/b][/color]")
		return null # todo fallback


func resolve_animation_path(stf_path: Array, context_object: Variant = null) -> STF_Module.ImportAnimationPropertyResult:
	if(len(stf_path) < 2): return null
	if(stf_path[0] in _imported_resources && stf_path[0] in _animation_converters):
		var resolver := _animation_converters[stf_path[0]]
		return resolver.call(stf_path, context_object if context_object else _imported_resources[stf_path[0]])
	return null


func register_exclusion_group_component(group: String, stf_type: String, stf_id: String):
	if(group not in _exclusion_groups): _exclusion_groups[group] = {stf_type: [stf_id]}
	elif(stf_type not in _exclusion_groups[group]): _exclusion_groups[group][stf_type] = [stf_id]
	else: _exclusion_groups[group][stf_type].append(stf_id)


func register_imported_resource(stf_id: String, result: STF_Module.ImportResult):
	_imported_resources[stf_id] = result._godot_object
	if(result._property_converter):
		_animation_converters[stf_id] = result._property_converter._callable


func resolve_exclusion_groups():
	for group in _exclusion_groups:
		var highest_module = null
		for group_type in _exclusion_groups[group]:
			var group_module = _modules[group_type]
			if(highest_module == null || group_module._get_priority() > highest_module._get_priority()):
				highest_module = group_module
		_exclusion_winners[group] = [highest_module._get_stf_type()]
		for group_type in _exclusion_groups[group]:
			if(group_type not in _exclusion_winners[group]):
				for overridden_id in _exclusion_groups[group][group_type]:
					_excluded_ids.append(overridden_id)


func get_buffer(stf_id: String) -> PackedByteArray:
	return _stf_file.get_buffer(_stf_file.json_definition["buffers"][stf_id]["index"])


func get_root_id() -> String:
	return _stf_file.json_definition["stf"]["root"]

