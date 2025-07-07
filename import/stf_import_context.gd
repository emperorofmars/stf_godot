class_name STF_ImportContext
extends RefCounted
## Is passed to each STF module on import


var _state: STF_ImportState


func _init(state: STF_ImportState) -> void:
	_state = state


func import(stf_id: String, expected_kind: String = "data", context_object: Variant = null) -> Variant:
	if(stf_id in _state._imported_resources):
		return _state._imported_resources[stf_id]
	var json_resource = _state.get_json_resource(stf_id)
	var module = _state.determine_module(json_resource, expected_kind)
	if(module):
		var ret = module._import(self, stf_id, json_resource, context_object)
		_state.register_imported_resource(stf_id, ret)
		return ret
	# scream error and fail hard
	return null


func get_buffer(stf_id: String) -> PackedByteArray:
	return _state.get_buffer(stf_id)
