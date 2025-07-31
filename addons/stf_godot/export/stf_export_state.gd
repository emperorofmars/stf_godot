class_name STF_ExportState
extends RefCounted
## Convert a Godot Scene into an STF_File


var _modules: Dictionary[String, Array]

var _meta := STF_Info.new()

# Godot Thingy -> STF ID
var _exported_resources: Dictionary[Object, String] = {}

# `resources` object of the STF definition
var _resources: Dictionary[String, Dictionary] = {}

var _buffers: Dictionary[String, PackedByteArray] = {}

var _root_id: String

var _tasks: Array[Callable] = []


func _init(modules: Dictionary[String, Array]) -> void:
	_modules = modules


func determine_module(godot_object: Object, expected_kind: String = "data") -> STF_Module:
	if(godot_object.get_class() in _modules):
		var candidates := _modules[godot_object.get_class()]

		var highest_score = -1
		var selected: STF_Module = null
		for candidate in candidates:
			var score = candidate._check_godot_object(godot_object)
			if(score > highest_score):
				highest_score = score
				selected = candidate
		if(selected):
			return selected

	print("STF Warning: Unrecognized object: %s" % godot_object)
	return null


func register_exported_resource(godot_object: Variant, exported_resource: STF_Module.ExportResult):
	_exported_resources[godot_object] = exported_resource._stf_id
	_resources[exported_resource._stf_id] = exported_resource._json_resource


func add_buffer(buffer: PackedByteArray) -> String:
	var id = GodotUUID.v4()
	_buffers[id] = buffer
	return id


func run_tasks():
	for task in _tasks:
		task.call()


func set_root_id(root_id):
	_root_id = root_id


func get_stf_file() -> STF_File:
	var ret = STF_File.new()

	ret.json_definition["stf"] = {
		"version_major": 0,
		"version_minor": 0,
		"root": _root_id,
		"asset_info": {}, # todo
		"generator": "stf_godot",
		"generator_version": "0.0.6", # todo
		"timestamp": Time.get_datetime_string_from_system(true),
		"metric_multiplier": 1 # todo
	}

	ret.json_definition["resources"] = _resources

	var buffers_object = {}
	for buffer_id in _buffers:
		buffers_object[buffer_id] = {
			"type": "stf.buffer.included",
			"index": ret.add_buffer(_buffers[buffer_id])
		}
	ret.json_definition["buffers"] = buffers_object

	#print(ret.json_definition)

	return ret
