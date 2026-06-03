class_name STFEXP_Node_Ethereal
extends STF_Handler

func _get_stf_type() -> String: return "stfexp.node.ethereal"
func _get_priority() -> int: return 0
func _get_stf_category() -> String: return "component"
func _get_like_types() -> Array[String]: return ["ethereal"]
func _get_godot_type() -> String: return "Node3D"

func _check_godot_object(godot_object: Variant) -> int:
	return 1 if godot_object is Node3D else -1

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var node: Node3D = context_object
	node.set_meta("stfexp_node_ethereal", stf_id)

	if(!context._get_import_options().get(STF_ImportOptions.AuthoringMode, false)):
		context._add_task(STF_ImportContext.PROCESS_STEPS.AFTER_ANIMATION, func():
			if(node.get_parent()):
				node.get_parent().remove_child(node)
			node.queue_free()
		)
	return ImportResult.new(null)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

