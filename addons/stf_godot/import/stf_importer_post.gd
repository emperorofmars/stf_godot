class_name STF_ImporterPost
extends EditorScenePostImportPlugin


func _post_process(root: Node):
	if(root.has_meta("stf")):
		var time_start := Time.get_ticks_usec()

		var handlers = STF_Registry.get_handlers_by_stf_type()
		for handler_type in handlers:
			handlers[handler_type]._import_post(root)

		if(!get_option_value(STF_ImportOptions.AuthoringMode)):
			__clean_stf_meta(root)

		var time_end := Time.get_ticks_usec()

		print_rich("[color=green]Successfully post-processed STF asset in ", (time_end - time_start) / 1000000.0, " s.[/color]")


func __clean_stf_meta(node: Node):
	if(node.has_meta("stf_id")): node.remove_meta("stf_id")
	if(node.has_meta("stf")): node.remove_meta("stf")
	if(node.has_meta("stf_instance_id")): node.remove_meta("stf_instance_id")
	if(node.has_meta("stf_instance")): node.remove_meta("stf_instance")
	if(node.has_meta("stf_resource")): node.remove_meta("stf_resource")
	for child in node.get_children(true):
		__clean_stf_meta(child)
