class_name STF_Godot_Util

static func get_name_or_default(json_resource: Dictionary, default: String = "Unnamed") -> String:
	if("name" in json_resource && json_resource["name"] is String && len(json_resource["name"]) > 0):
		return StringName(json_resource["name"])
	else:
		return default


static func get_bone_from_skeleton(skeleton: Skeleton3D, bone_id: String) -> int:
	var bone_index = -1
	for i in range(skeleton.get_bone_count()):
		if(skeleton.get_bone_meta(i, "stf_id") == bone_id):
			bone_index = i
			break
	return bone_index


static func get_resource_reference(json_resource: Dictionary, reference_index: int) -> String:
	var ref: Array = json_resource.get("referenced_resources", [])
	if(len(ref) > reference_index):
		return ref[reference_index]
	else:
		return ""

