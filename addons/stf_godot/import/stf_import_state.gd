class_name STF_ImportState
extends RefCounted
## Parse an STF_File into Godot constructs


var _stf_file: STF_File
var _modules: Dictionary[String, STF_Module]

var _meta: STF_Info

# STF ID -> Godot Thingy
var _imported_resources: Dictionary[String, Variant] = {}

var _animation_converters: Dictionary[Object, STF_AnimationPropertyResolver] = {}

var _tasks: Array[Callable] = []


func _init(stf_file: STF_File, modules: Dictionary[String, STF_Module]) -> void:
	_stf_file = stf_file
	_modules = modules
	_meta = STF_Info.parse(_stf_file.json_definition)


func get_json_resource(stf_id: String) -> Dictionary:
	return _stf_file.json_definition["resources"][stf_id]


func determine_module(json_resource: Dictionary, expected_kind: String = "data") -> STF_Module:
	if(json_resource["type"] in _modules):
		return _modules[json_resource["type"]]
	else:
		print("STF Warning: Unrecognized resource: %s" % json_resource["type"])
		return null # todo fallback


func resolve_animation_path(stf_path: Array[String]) -> STF_AnimationPropertyResult:
	if(len(stf_path) > 0 && stf_path[0] in _imported_resources && _imported_resources[stf_path[0]] in _animation_converters):
		var resolver := _animation_converters[_imported_resources[stf_path[0]]]
		return resolver.resolve(stf_path.slice(1), _imported_resources[stf_path[0]])
	
	return null


func register_imported_resource(stf_id: String, resource: Variant):
	_imported_resources[stf_id] = resource


func get_buffer(stf_id: String) -> PackedByteArray:
	return _stf_file.get_buffer(_stf_file.json_definition["buffers"][stf_id]["index"])


func get_root_id() -> String:
	return _stf_file.json_definition["stf"]["root"]


func run_tasks():
	for task in _tasks:
		task.call()
