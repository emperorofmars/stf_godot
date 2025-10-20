class_name STF_Exporter
## Exports the given root-node into the STF_File slass, which can write to disk.

static func export(path: String, root: SceneTree):
	print_rich("Exporting STF asset: [u]", path, "[/u]")

	var time_start := Time.get_ticks_usec()

	var export_state = STF_ExportState.new(STF_Registry.get_modules_by_godot_type())
	var export_context = STF_ExportContext.new(export_state)

	var root_id := export_context.export(root, "data")
	if(root_id):
		export_state.set_root_id(root_id)
		export_state.get_stf_file().write(path)
		
		var time_end := Time.get_ticks_usec()

		print_rich("[color=green]Successfully exported STF asset [u]", path, "[/u] in ", (time_end - time_start) / 1000.0, " ms.[/color]")
	else:
		print_rich("[color=red]Failed to export STF asset [u]", path, "[/u][/color]")

