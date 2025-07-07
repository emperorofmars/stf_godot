class_name STF_ResourceExport
extends RefCounted

var stf_id: String
var json_resource: Dictionary

func _init(stf_id: String, json_resource: Dictionary) -> void:
	self.stf_id = stf_id
	self.json_resource = json_resource