class_name STF_ResourceExport
extends RefCounted

var _stf_id: String
var _json_resource: Dictionary

func _init(stf_id: String, json_resource: Dictionary) -> void:
	self._stf_id = stf_id
	self._json_resource = json_resource
