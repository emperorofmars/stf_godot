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

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var ret = Node3D.new()
	ret.name = json_resource.get("name", "STF Prefab")

	ret.set_meta("stf_id", stf_id)
	var stf_meta := {"stf_name": json_resource.get("name", null)}
	ret.set_meta("stf", stf_meta)

	for child_id in json_resource.get("root_nodes", []):
		var child: Node3D = context.import(child_id, "node", ret)
		ret.add_child(child)

	for animation_id in json_resource.get("animations", []):
		var animation = context.import(animation_id, "data", ret)
		# todo add to a animation node or something

	context._add_task(func():
		__set_owner(ret, ret)
	)
	return ret

func _export() -> STF_ResourceExport:
	return null


func __set_owner(root: Node, owner: Node):
	for child in root.get_children(true):
		child.set_owner(owner)
		__set_owner(child, owner)
