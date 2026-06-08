class_name STF_ExportContext
extends RefCounted
## Is passed to each STF module on export


var _state: STF_ExportState


func _init(state: STF_ExportState) -> void:
	_state = state

func export_set_reference(resource_json: Dictionary, godot_object: Variant, expected_kind: String = "data", context_object: Variant = null, instance_context: Variant = null) -> int:
	var stf_id = export(godot_object, expected_kind, context_object, instance_context)
	if(!stf_id): return -1
	if("referenced_resources" not in resource_json):
		resource_json["referenced_resources"] = []
	if(stf_id not in resource_json["referenced_resources"]):
		resource_json["referenced_resources"].append(stf_id)
		return len(resource_json["referenced_resources"]) - 1
	else:
		return resource_json["referenced_resources"].find(stf_id)

func export(godot_object: Variant, expected_kind: String = "data", context_object: Variant = null, instance_context: Variant = null) -> String:
	if(godot_object in _state._exported_resources):
		return _state._exported_resources[godot_object]

	var handler = _state.determine_handler(godot_object, expected_kind)
	if(handler):
		var ret = handler._export(self, godot_object, context_object, instance_context)
		if(ret):
			_state.register_exported_resource(godot_object, ret)

			if(expected_kind in ["data", "node"]):
				for component in ret._components:
					var component_id = export(component, "component", godot_object, instance_context)
					if(component_id):
						if("components" not in ret._json_resource): ret._json_resource["components"] = []
					ret._json_resource["components"].append(component_id)
			return ret._stf_id
		else:
			print_rich("[color=red]Error: Failed to export Godot object [u]" + str(godot_object) + "[/u][/color]")
			return ""
	else:
		return ""


func add_buffer(buffer: PackedByteArray, stf_id: String = "") -> String:
	return _state.add_buffer(buffer, stf_id)


func _add_task(task: Callable):
	_state._tasks.append(task)

