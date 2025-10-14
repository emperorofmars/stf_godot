class_name STF_ImportContext
extends RefCounted
## Is passed to each STF module on import


var _state: STF_ImportState

# Dictionary[int, Array[Callable]]
var _tasks: Dictionary[int, Array] = {}
var _current_step := 0

enum PROCESS_STEPS { DEFAULT = 100, BEFORE_MATERIAL = 1000, MATERIAL = 1010, AFTER_MATERIAL = 1020, BEFORE_ANIMATION = 10000, ANIMATION = 10010, AFTER_ANIMATION = 10020, FINALE = 10000000 }


func _init(state: STF_ImportState) -> void:
	_state = state


func import(stf_id: String, expected_kind: String = "data", context_object: Variant = null) -> Variant:
	if(stf_id in _state._imported_resources):
		return _state._imported_resources[stf_id]
	var json_resource = _state.get_json_resource(stf_id)
	var module = _state.determine_module(json_resource, expected_kind)
	if(module):
		var ret: = module._import(self, stf_id, json_resource, context_object)
		if(ret):
			_state.register_imported_resource(stf_id, ret)

			if(expected_kind in ["data", "node"] && "components" in json_resource):
				for component_id in json_resource["components"]:
					var json_component_resource = _state.get_json_resource(component_id)
					var component_module = _state.determine_module(json_component_resource, "component")
					if(component_module):
						var component_ret: = component_module._import(self, component_id, json_component_resource, ret._godot_object)
						if(component_ret):
							_state.register_imported_resource(stf_id, component_ret)
						else:
							print_rich("[color=red]Error: Failed to import component resource [u]" + stf_id + "[/u][/color]")
			return ret._godot_object
		else:
			print_rich("[color=red]Error: Failed to import resource [u]" + stf_id + "[/u][/color]")
	return null


func resolve_animation_path(stf_path: Array, context_object: Variant = null) -> STF_Module.ImportAnimationPropertyResult:
	return _state.resolve_animation_path(stf_path, context_object)


func get_buffer(stf_id: String) -> PackedByteArray:
	return _state.get_buffer(stf_id)


func _add_task(step: int, task: Callable):
	if(step < self._current_step):
		step = self._current_step
	if(step not in _tasks):
		_tasks[step] = [task]
	else:
		_tasks[step].append(task)

func _run_tasks():
	const max_depth: = 1000
	self._current_step = 0
	for task_step in self._tasks:
		var iter: = 0
		while(len(_tasks) > 0 && iter < max_depth):
			var tmp = self._tasks[task_step]
			self._tasks[task_step] = []
			for task in tmp:
				task.call()
			iter += 1


func _get_import_options() -> Dictionary:
	return _state._import_options
