class_name STF_Prefab
extends STF_Module

func get_stf_type() -> String:
	return "stf.prefab"

func get_priority() -> int:
	return 0

func get_stf_kind() -> String:
	return "data"

func get_like_types() -> Array[String]:
	return ["prefab"]

func get_godot_type() -> String:
	return "Node3D"

func import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var ret = Node3D.new()
	ret.name = json_resource.get("name", "STF Prefab")
	for child_id in json_resource.get("root_nodes", []):
		var child: Node3D = context.import(child_id, "node", ret)
		ret.add_child(child)

	set_owner(ret, ret)

	return ret

func export() -> STF_ResourceExport:
	return null


func set_owner(root: Node, owner: Node):
	for child in root.get_children(true):
		child.set_owner(owner)
		set_owner(child, owner)