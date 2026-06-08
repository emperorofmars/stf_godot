class_name STF_Prefab
extends STF_Handler
## Representation of an STF asset.
## Imports into a Godot Scene and its root Node3D.
##
## [url]https://docs.stfform.at/resources/stf/stf_prefab.html[/url]

func _get_stf_type() -> String: return "stf.prefab"
func _get_priority() -> int: return 0
func _get_stf_category() -> String: return "data"
func _get_like_types() -> Array[String]: return ["prefab"]
func _get_godot_types() -> Array[String]: return ["SceneTree"]

func _check_godot_object(godot_object: Variant) -> int:
	return 0

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var ret: Node3D = null
	var root_type = context._get_import_options().get("nodes/root_type")
	if(root_type && len(root_type) > 0):
		if(ClassDB.can_instantiate(root_type) && ClassDB.is_parent_class(root_type, "Node3D")):
			ret = ClassDB.instantiate(root_type)
		else:
			print_rich("[color=red]Can not instantiate " + root_type + "! Falling back to Node3D[/color]")
			ret = Node3D.new()
	else:
		ret = Node3D.new()

	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Prefab")

	var stf_resource := _set_stf_meta(STF_ResourceHelper.new(context, stf_id, json_resource, _get_stf_category()), ret)

	for child_id in json_resource.get("root_nodes", []):
		var child: Node3D = stf_resource.import(child_id, "node", ret, ret)
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
				var animation: Animation = stf_resource.import(animation_id, "data")
				if(animation):
					animation_library.add_animation(animation.resource_name, animation)
		)

	return ImportResult.new(ret)

func __set_owner(root: Node, owner: Node):
	for child in root.get_children(true):
		child.set_owner(owner)
		__set_owner(child, owner)


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant, instance_context: Variant) -> ExportResult:
	var scene: SceneTree = godot_object
	var root_node := scene.edited_scene_root

	var stf_id := ""
	if(root_node.has_meta("stf")):
		stf_id = root_node.get_meta("stf")["stf_id"]
	else:
		stf_id = GodotUUID.v4()
		root_node.set_meta("stf", {"stf_id": stf_id})

	var ret = {
		"type": _get_stf_type()
	}

	var stf_name = str(root_node.name)
	if(root_node.has_meta("stf") && root_node.get_meta("stf").has("stf_name")):
		stf_name = root_node.get_meta("stf")["stf_name"]
	ret["name"] = stf_name

	var root_nodes = []


	for child in root_node.get_children():
		if(child is AnimationPlayer || child is AnimationTree || child is not Node3D):
			continue

		var child_id_index = context.export_set_reference(ret, child, "node", root_node, root_node)
		if(child_id_index >= 0):
			root_nodes.append(child_id_index)
	ret["root_nodes"] = root_nodes

	return ExportResult.new(stf_id, ret)
