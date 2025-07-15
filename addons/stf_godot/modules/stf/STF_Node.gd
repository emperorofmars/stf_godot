class_name STF_Node
extends STF_Module

func _get_stf_type() -> String:
	return "stf.node"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "node"

func _get_like_types() -> Array[String]:
	return ["node"]

func _get_godot_type() -> String:
	return "Node3D"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var ret = null
	if("instance" in json_resource):
		ret = context.import(json_resource["instance"], "instance", context_object)
	else:
		ret = Node3D.new()
	ret.name = json_resource.get("name", "STF Node")

	ret.set_meta("stf_id", stf_id)
	var stf_meta = ret.get_meta("stf", {})
	stf_meta["stf_name"] = json_resource.get("name", null)
	#ret.set_meta("stf", stf_meta)
	
	for child_id in json_resource.get("children", []):
		var child: Node3D = context.import(child_id, "node", context_object)
		ret.add_child(child)
	
	if("trs" in json_resource):
		ret.transform = STF_TRS_Util.parse_transform(json_resource["trs"])
	
	if("parent_binding" in json_resource && len(json_resource["parent_binding"]) == 3):
		context._add_task(func():
			var parent_binding: Array = json_resource["parent_binding"]
			var parent: Node = ret.get_parent()
			if(parent.is_class("Skeleton3D")):
				var bone_id = parent_binding[2]
				var bone_index = -1
				for i in range(parent.get_bone_count()):
					if(parent.get_bone_meta(i, "stf_id") == bone_id):
						bone_index = i
						break
				if(bone_index < 0): return

				var bone_attachment = BoneAttachment3D.new()
				bone_attachment.name = ret.name + "_parent_binding"
				bone_attachment.set_meta("stf", {"stf_parent_binding_for": stf_id})
				parent.add_child(bone_attachment)
				bone_attachment.bone_idx = bone_index
				parent.remove_child(ret)
				bone_attachment.add_child(ret)
				ret.transform = parent.get_bone_global_rest(bone_index).inverse() * ret.transform
		)

	return ret

func _export() -> STF_ResourceExport:
	return null
