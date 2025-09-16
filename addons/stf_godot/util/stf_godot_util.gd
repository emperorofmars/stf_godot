class_name STF_Godot_Util

static func get_name_or_default(json_resource: Dictionary, default: String = "Unnamed") -> String:
	if("name" in json_resource && json_resource["name"] is String && len(json_resource["name"]) > 0):
		return StringName(json_resource["name"])
	else:
		return default
