class_name STF_Resource
extends RefCounted

var _context: STF_ImportContext
var _meta : Dictionary


func _init(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, stf_kind: String) -> void:
	self._context = context

	var buffers := {}
	for buffer_id in json_resource.get("referenced_buffers", []):
		buffers[buffer_id] = context.get_buffer(buffer_id)

	self._meta = {
		"stf_id": stf_id,
		"stf_name": json_resource.get("name"),
		"stf_type": json_resource["type"],
		"stf_kind": stf_kind,
		"original_json": json_resource,
		"buffers": buffers,
		"referenced_resources": {},
		"processed": [],
	}


func get_buffer(stf_id: String) -> PackedByteArray:
	if(stf_id in _meta["buffers"]):
		return _meta["buffers"][stf_id]
	else:
		var ret := _context.get_buffer(stf_id)
		_meta["buffers"][stf_id] = ret
		return ret


func register_referenced_resource(stf_id: String, resource: Variant):
	_meta["referenced_resources"][stf_id] = resource

func register_processed_object(resource: Variant):
	_meta["processed"].append(resource)


func add_meta(key: String, value: Variant):
	_meta[key] = value
