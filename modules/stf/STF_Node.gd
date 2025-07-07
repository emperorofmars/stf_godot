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
	for child_id in json_resource.get("children", []):
		var child: Node3D = context.import(child_id, "node", context_object)
		ret.add_child(child)

	ret.set_meta("stf_id", stf_id)
	ret.set_meta("stf_name", json_resource.get("name", null))

	return ret

func _export() -> STF_ResourceExport:
	return null
