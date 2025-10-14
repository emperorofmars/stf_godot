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


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var ret = Node3D.new()
	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Prefab")
	STF_Godot_Util.set_stf_meta(stf_id, json_resource, ret)

	for child_id in json_resource.get("root_nodes", []):
		var child: Node3D = context.import(child_id, "node", ret)
		ret.add_child(child)

	context._add_task(context.PROCESS_STEPS.BEFORE_ANIMATION, func(): __set_owner(ret, ret))

	if("animations" in json_resource):
		context._add_task(context.PROCESS_STEPS.ANIMATION, func():
			var animation_player := AnimationPlayer.new()
			animation_player.name = "Imported STF Animations"
			ret.add_child(animation_player)
			animation_player.set_owner(ret)

			var animation_library := AnimationLibrary.new()
			animation_library.resource_name = "Imported STF Animations"
			animation_player.add_animation_library("STF", animation_library)

			for animation_id in json_resource["animations"]:
				var animation: Animation = context.import(animation_id, "data", ret)
				if(animation):
					animation_library.add_animation(animation.resource_name, animation)
		)

	return ImportResult.new(ret)

func __set_owner(root: Node, owner: Node):
	for child in root.get_children(true):
		child.set_owner(owner)
		__set_owner(child, owner)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
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

	return ExportResult.new(stf_id, ret)
