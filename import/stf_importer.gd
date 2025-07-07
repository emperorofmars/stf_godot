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
	return [{"name": "authoring_import", "default_value": false}]

func _get_option_visibility(path: String, for_animation: bool, option: String):
	if(option == "authoring_import"):
		return true
	return false

func _import_scene(path: String, flags: int, options: Dictionary) -> Object:
	print("Importing STF asset: " + path)
	
	var stf_file = STF_File.read(path)
	if(not stf_file):
		return null

	var import_state = STF_ImportState.new(stf_file, STF_Registry.get_modules_by_stf_type())
	var import_context = STF_ImportContext.new(import_state)
	var ret = import_context.import(import_state.get_root_id())
	
	return ret
