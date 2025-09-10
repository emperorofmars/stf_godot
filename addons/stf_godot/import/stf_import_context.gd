class_name STF_ImportContext
extends RefCounted
## Is passed to each STF module on import


var _state: STF_ImportState

var _tasks: Array[Callable] = []


func _init(state: STF_ImportState) -> void:
	_state = state


func import(stf_id: String, expected_kind: String = "data", context_object: Variant = null) -> Variant:
	if(stf_id in _state._imported_resources):
		return _state._imported_resources[stf_id]
	var json_resource = _state.get_json_resource(stf_id)
	var module = _state.determine_module(json_resource, expected_kind)
	if(module):
		var ret := module._import(self, stf_id, json_resource, context_object)
		if(ret):
			_state.register_imported_resource(stf_id, ret)

			if(expected_kind in ["data", "node"] && "components" in json_resource):
				for component_id in json_resource["components"]:
					var json_component_resource = _state.get_json_resource(component_id)
					var component_module = _state.determine_module(json_component_resource, "component")
					if(component_module):
						component_module._import(self, component_id, json_component_resource, ret._godot_object)
			return ret._godot_object
		else:
			#todo report error
			pass
	# todo scream error and fail hard
	return null


func resolve_animation_path(stf_path: Array, context_object: Variant = null) -> STF_Module.ImportAnimationPropertyResult:
	return _state.resolve_animation_path(stf_path, context_object)


func get_buffer(stf_id: String) -> PackedByteArray:
	return _state.get_buffer(stf_id)


func _add_task(task: Callable):
	_tasks.append(task)

func _run_tasks():
	for task in _tasks:
		task.call()
	_tasks.clear()


func _get_import_options() -> Dictionary:
	return _state._import_options
