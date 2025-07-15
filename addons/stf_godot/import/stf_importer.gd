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
	add_import_option_advanced(TYPE_BOOL, "authoring_import", false)
	add_import_option_advanced(TYPE_BOOL, "use_asset_name", false)

#func _get_option_visibility(path: String, for_animation: bool, option: String):
#	return option in ["authoring_import", "use_asset_name", "nodes/root_name", "nodes/root_type", "nodes/apply_root_scale"]
	#return true

func _import_scene(path: String, flags: int, options: Dictionary) -> Object:
	print("Importing STF asset: " + path)
	
	var stf_file = STF_File.read(path)
	if(not stf_file):
		return null

	var import_state = STF_ImportState.new(stf_file, STF_Registry.get_modules_by_stf_type())
	var import_context = STF_ImportContext.new(import_state)
	var ret: Node3D = import_context.import(import_state.get_root_id())
	import_state.run_tasks()

	if(options["use_asset_name"]):
		ret.name = path.get_file().get_basename()

	ret.set_meta("stf_import_meta", import_state._stf_file.json_definition["stf"])

	return ret

