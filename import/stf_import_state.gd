class_name STF_ImportState
extends RefCounted
## Parse an STF_File into Godot constructs


var _stf_file: STF_File
var _modules: Dictionary[String, STF_Module]

var _meta: STF_Info

## STF ID -> Godot Thingy
var _imported_resources: Dictionary[String, Variant] = {}


func _init(stf_file: STF_File, modules: Dictionary[String, STF_Module]) -> void:
	_stf_file = stf_file
	_modules = modules


func get_root_id() -> String:
	return _stf_file.json_definition["stf"]["root"]
