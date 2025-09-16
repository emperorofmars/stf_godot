class_name STF_Importer
extends EditorSceneFormatImporter

func _get_importer_name():
	return "STF - Squirrel Transfer Format"

func _get_recognized_extensions() -> Array:
	return ["stf"]

func _get_extensions() -> PackedStringArray:
	return PackedStringArray(["stf"])

func _get_import_flags() -> int:
	return IMPORT_SCENE


func _get_import_options(path: String):
	if(path and path.get_extension() != "stf"): return

	add_import_option_advanced(TYPE_BOOL, "authoring_import", false)
	add_import_option_advanced(TYPE_BOOL, "use_asset_name", false)
	add_import_option_advanced(TYPE_INT, "animation_handling", 1, PROPERTY_HINT_ENUM, "Prefer Bezier -> Baked -> Simplified,Prefer Baked -> Simplified,Prefer Simplified")
	add_import_option_advanced(TYPE_BOOL, "enable_debug_log", false)
	#add_import_option_advanced(TYPE_DICTIONARY, "target_materials", {}, PROPERTY_HINT_RESOURCE_TYPE, "Material")

func _get_option_visibility(path: String, for_animation: bool, option: String):
	if(path and path.get_extension() != "stf"): return false
	return option not in ["nodes/import_as_skeleton_bones", "nodes/use_node_type_suffixes"]



func _import_scene(path: String, flags: int, options: Dictionary) -> Object:
	if(options.get("enable_debug_log", false)):
		print_rich("Importing STF asset: [u]", path, "[/u]")

	var time_start := Time.get_ticks_msec()
	
	var stf_file = STF_File.read(path)
	if(not stf_file):
		return null

	var import_state = STF_ImportState.new(stf_file, STF_Registry.get_modules_by_stf_type(), options)
	var import_context = STF_ImportContext.new(import_state)
	var ret: Node3D = import_context.import(import_state.get_root_id())
	import_context._run_tasks()

	if(options["use_asset_name"]):
		ret.name = path.get_file().get_basename()
	elif(options["nodes/root_name"]):
		ret.name = options["nodes/root_name"]

	if(options["authoring_import"]):
		var stf_meta = ret.get_meta("stf", {})
		stf_meta["import_meta"] = import_state._stf_file.json_definition["stf"]
	else:
		__clean_stf_meta(ret)

	var time_end := Time.get_ticks_msec()

	print_rich("[color=green]Successfully imported STF asset [u]", path, "[/u] in ", time_end - time_start, " ms.[/color]")
	return ret


func __clean_stf_meta(node: Node):
	if(node.has_meta("stf_id")): node.remove_meta("stf_id")
	if(node.has_meta("stf")): node.remove_meta("stf")
	for child in node.get_children(true):
		__clean_stf_meta(child)
