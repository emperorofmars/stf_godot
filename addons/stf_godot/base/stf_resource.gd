class_name STF_Resource
extends RefCounted

var _context: STF_ImportContext
var _meta : Dictionary


func _init(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, stf_category: String) -> void:
	self._context = context

	var buffers := {}
	for buffer_id in json_resource.get("referenced_buffers", []):
		buffers[buffer_id] = context.get_buffer(buffer_id)

	self._meta = {
		"stf_id": stf_id,
		"stf_name": json_resource.get("name"),
		"stf_type": json_resource["type"],
		"stf_category": stf_category,
		"original_json": json_resource,
		"buffers": buffers,
		"referenced_resources": {},
		"processed": [],
	}


func import(resource_id: Variant, expected_kind: String = "data", context_object: Variant = null, instance_context: Variant = null) -> Variant:
	var actual_resource_id = null
	if(resource_id == null):
		print("Invalid resource reference")
		print_stack()
		return null
	if(resource_id is int or resource_id is float):
		var ref: Array = _meta["original_json"].get("referenced_resources", [])
		if(len(ref) > resource_id):
			actual_resource_id = ref[int(resource_id)]
		else:
			print("Invalid resource reference index")
			print_stack()
			return null
	else:
		actual_resource_id = resource_id
	return _context.import(actual_resource_id, expected_kind, context_object, instance_context)


func get_buffer(buffer_id: Variant) -> PackedByteArray:
	if(buffer_id is int or buffer_id is float):
		var ref: Array = _meta["original_json"].get("referenced_buffers", [])
		if(len(ref) > buffer_id):
			return _meta["buffers"][ref[int(buffer_id)]]
	elif(buffer_id is String):
		if(buffer_id in _meta["buffers"]):
			return _meta["buffers"][buffer_id]
		else:
			return _context.get_buffer(buffer_id)
	return PackedByteArray()


func register_referenced_resource(stf_id: String, resource: Variant):
	_meta["referenced_resources"][stf_id] = resource

func register_processed_object(resource: Variant):
	_meta["processed"].append(resource)


func add_meta(key: String, value: Variant):
	_meta[key] = value
