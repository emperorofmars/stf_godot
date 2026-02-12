class_name STF_ImportContext
extends RefCounted
## Is passed to each STF module on import


var _state: STF_ImportState

# Dictionary[int, Array[Callable]]
var _tasks: Dictionary[int, Array] = {}
var _current_step := 0

enum PROCESS_STEPS {
	DEFAULT = 10000, # Node Hierarchy / Resources / Instances
	BEFORE_COMPONENTS = 20000,
	COMPONENTS = 21000,
	AFTER_COMPONENTS = 22000,
	BEFORE_MATERIAL = 30000,
	MATERIAL = 31000,
	AFTER_MATERIAL = 32000,
	BEFORE_ANIMATION = 40000,
	ANIMATION = 41000,
	AFTER_ANIMATION = 42000,
	FINALE = 10000000
}


func _init(state: STF_ImportState) -> void:
	_state = state


func import(stf_id: String, expected_kind: String = "data", context_object: Variant = null, instance_context: Variant = null) -> Variant:
	if(stf_id in _state._imported_resources):
		return _state._imported_resources[stf_id]
	var json_resource = _state.get_json_resource(stf_id)
	var module = _state.determine_module(json_resource, expected_kind)
	if(module && module._get_stf_kind() == expected_kind):
		var ret := module._import(self, stf_id, json_resource, context_object, instance_context if module._get_stf_kind() != "data" else null)
		if(ret):
			_state.register_imported_resource(stf_id, ret)

			if(module._get_stf_kind() in ["data", "node"] && "components" in json_resource):
				var component_instance_context = instance_context if module._get_stf_kind() != "data" else ret._godot_object

				for component_id in json_resource["components"]:
					import_component(component_id, ret._godot_object, component_instance_context)

			return ret._godot_object
		else:
			print_rich("[color=red]Error: Failed to import resource [u]" + stf_id + "[/u][/color]")
	return null


func import_component(component_id: String, context_object: Variant = null, instance_context: Variant = null):
	var json_component_resource = _state.get_json_resource(component_id)
	var component_module: STF_ModuleComponent  = _state.determine_module(json_component_resource, "component")
	if(component_module and component_module is STF_ModuleComponent):
		var component_pre_import_ret: = component_module._component_pre_import(self, component_id, json_component_resource, context_object, instance_context)
		if(component_pre_import_ret and component_pre_import_ret._success == true):
			if(component_pre_import_ret._exclusion_group && component_pre_import_ret._exclusion_group.length() > 0):
				_state.register_exclusion_group_component(component_pre_import_ret._exclusion_group, component_module._get_stf_type(), component_id)
			if(instance_context not in _state._component_instance_context): _state._component_instance_context[instance_context] = []
			var component_handle_func: Callable = __create_handle_component_instance_func(component_id, component_module, json_component_resource, context_object)
			_state._component_instance_context[instance_context].append(component_handle_func)
			_add_task(PROCESS_STEPS.COMPONENTS, func(): component_handle_func.call(instance_context))


func import_component_instance_mod(instantiated_resource: Variant, component_id: String, mod_json: Dictionary):
	if(instantiated_resource not in _state._component_instance_mods): _state._component_instance_mods[instantiated_resource] = {}
	_state._component_instance_mods[instantiated_resource][component_id] = mod_json

# Allow these tasks to be executed per instance of their context (i.e. components on armatures & bones)
func handle_instance(instantiated_resource: Variant, instance: Variant):
	for task in _state._component_instance_context.get(instantiated_resource, []):
		task.call(instance)


func __create_handle_component_instance_func(component_id: String, component_module: STF_ModuleComponent, json_component_resource: Dictionary, context_object: Variant) -> Callable:
	return func(component_instance_context: Variant):
		if(component_id not in _state._excluded_ids):
			var mod_json = _state._component_instance_mods.get(component_instance_context, {}).get(component_id)
			var json = mod_json if mod_json else json_component_resource
			var component_ret: = component_module._import(self, component_id, json, context_object, component_instance_context)
			if(component_ret):
				_state.register_imported_resource(component_id, component_ret)
			else:
				print_rich("[color=red]Error: Failed to import component resource [u]" + component_id + "[/u][/color]")


func import_instance_mod(stf_id: String, mod_json: Dictionary, context_object: Variant) -> Variant:
	var json_resource = _state.get_json_resource(stf_id)
	var module = _state.determine_module(json_resource, "component")
	if(module && module is STF_ModuleComponent):
		var component_module: STF_ModuleComponent = module
		component_module._import_instance_mod(self, stf_id, mod_json, context_object)
	return null


func resolve_animation_path(stf_path: Array, context_object: Variant = null) -> STF_Module.ImportAnimationPropertyResult:
	return _state.resolve_animation_path(stf_path, context_object)


func get_buffer(stf_id: String) -> PackedByteArray:
	return _state.get_buffer(stf_id)


func _add_task(step: int, task: Callable):
	if(step <= self._current_step):
		step = self._current_step + 1
	if(step not in _tasks):
		_tasks[step] = [task]
	else:
		_tasks[step].append(task)

func _run_tasks():
	const max_depth: = 1000
	self._current_step = 0
	self._tasks.sort()
	for task_step in self._tasks:
		self._current_step = task_step
		var iter: = 0
		while(len(_tasks) > 0 && iter < max_depth):
			var tmp = self._tasks[task_step]
			self._tasks[task_step] = []
			for task in tmp:
				task.call()
			iter += 1


func _get_import_options() -> Dictionary:
	return _state._import_options
