class_name STF_Prefab
extends STF_Module

func _get_stf_type() -> String:
	return "stf.prefab"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "data"

func _get_like_types() -> Array[String]:
	return ["prefab"]

func _get_godot_type() -> String:
	return "SceneTree"

func _check_godot_object(godot_object: Object) -> int:
	return 0


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var ret = Node3D.new()
	ret.name = json_resource.get("name", "STF Prefab")

	ret.set_meta("stf_id", stf_id)
	var stf_meta := {"stf_name": json_resource.get("name", null)}
	ret.set_meta("stf", stf_meta)

	for child_id in json_resource.get("root_nodes", []):
		var child: Node3D = context.import(child_id, "node", ret)
		ret.add_child(child)

	if("animations" in json_resource):
		var animation_player := AnimationPlayer.new()
		animation_player.name = "Imported STF Animations"
		var animation_library := AnimationLibrary.new()
		animation_library.resource_name = "Imported STF Animations"
		animation_player.add_animation_library("STF", animation_library)
		ret.add_child(animation_player)

		for animation_id in json_resource["animations"]:
			var animation: Animation = context.import(animation_id, "data", ret)
			if(animation):
				animation_library.add_animation(animation.resource_name, animation)

	context._add_task(func():
		__set_owner(ret, ret)
	)
	return ret

func __set_owner(root: Node, owner: Node):
	for child in root.get_children(true):
		child.set_owner(owner)
		__set_owner(child, owner)


func _export(context: STF_ExportContext, godot_object: Object, context_object: Variant) -> STF_ResourceExport:
	var scene: SceneTree = godot_object
	var root_node := scene.edited_scene_root

	var stf_id := ""
	if(root_node.has_meta("stf_id")):
		stf_id = root_node.get_meta("stf_id")
	else:
		stf_id = GodotUUID.v4()
		root_node.set_meta("stf_id", stf_id)

	var ret = {
		"type": _get_stf_type()
	}

	var stf_name = root_node.name
	if(root_node.has_meta("stf") && root_node.get_meta("stf").has_meta("stf_name")):
		stf_name = root_node.get_meta("stf")["stf_name"]
	ret["name"] = stf_name

	return STF_ResourceExport.new(stf_id, ret)
