class_name STF_Exporter
## Exports the given root-node into the STF_File slass, which can write to disk.

static func export(path: String, root: SceneTree):
	print("Exporting STF asset: " + path)

	var export_state = STF_ExportState.new(STF_Registry.get_modules_by_godot_type())
	var export_context = STF_ExportContext.new(export_state)

	var root_id := export_context.export(root, "data")
	if(root_id):
		export_state.set_root_id(root_id)
		export_state.get_stf_file().write(path)
	else:
		pass # todo scream errors

