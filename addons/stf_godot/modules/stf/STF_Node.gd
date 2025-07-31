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


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var ret = null
	if("instance" in json_resource):
		ret = context.import(json_resource["instance"], "instance", context_object)
	else:
		ret = Node3D.new()
	ret.name = json_resource.get("name", "STF Node")

	ret.set_meta("stf_id", stf_id)
	var stf_meta = ret.get_meta("stf", {})
	stf_meta["stf_name"] = json_resource.get("name", null)
	ret.set_meta("stf", stf_meta)

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

	if("enabled" in json_resource && json_resource["enabled"] == false):
		ret.visible = false

	var animation_property_resolve_func = func (stf_path: Array, godot_object: Object):
		if(len(stf_path) < 2): return null
		var node: Node3D = godot_object
		var path = node.owner.get_path_to(node).get_concatenated_names()
		match stf_path[1]:
			"t": return AnimationPropertyResult.new(path + ":position", Animation.TYPE_POSITION_3D)
			"r": return AnimationPropertyResult.new(path + ":rotation", Animation.TYPE_ROTATION_3D)
			"s": return AnimationPropertyResult.new(path + ":scale", Animation.TYPE_SCALE_3D)
			"enabled": return AnimationPropertyResult.new(path + ":visible", Animation.TYPE_VALUE) # todo does this work?
			"instance":
				var anim_ret := context.resolve_animation_path([ret.get_meta("stf").get("stf_instance_id")] + stf_path.slice(2)) # slightly dirty but it works
				if(anim_ret):
					return AnimationPropertyResult.new(anim_ret._godot_path, anim_ret._track_type, anim_ret._keyframe_converter) # todo does this work?
				return null
			"components":
				return null # todo
		return null

	return ImportResult.new(ret, OptionalCallable.new(animation_property_resolve_func))


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
