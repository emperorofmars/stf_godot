class_name STF_Node
extends STF_Module

func get_stf_type() -> String:
	return "stf.node"

func get_priority() -> int:
	return 0

func get_stf_kind() -> String:
	return "node"

func get_like_types() -> Array[String]:
	return ["node"]

func get_godot_type() -> String:
	return "Node3D"

func import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var ret = Node3D.new()
	ret.name = json_resource.get("name", "STF Node")
	for child_id in json_resource.get("children", []):
		var child: Node3D = context.import(child_id, "node", ret)
		ret.add_child(child)
	return ret

func export() -> STF_ResourceExport:
	return null
