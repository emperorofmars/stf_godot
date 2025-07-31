class_name STF_ExportContext
extends RefCounted
## Is passed to each STF module on export


var _state: STF_ExportState


func _init(state: STF_ExportState) -> void:
	_state = state


func export(godot_object: Variant, expected_kind: String = "data", context_object: Variant = null) -> String:
	if(godot_object in _state._exported_resources):
		return _state._exported_resources[godot_object]

	var module = _state.determine_module(godot_object, expected_kind)
	if(module):
		var ret = module._export(self, godot_object, context_object)
		if(ret):
			_state.register_exported_resource(godot_object, ret)

			if(expected_kind in ["data", "node"]):
				# todo components
				pass
			return ret._stf_id
		else:
			# todo report error
			pass
	# todo scream error and fail hard
	return ""


func add_buffer(buffer: PackedByteArray):
	_state.add_buffer(buffer)


func _add_task(task: Callable):
	_state._tasks.append(task)

