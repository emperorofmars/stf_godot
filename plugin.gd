@tool
extends EditorPlugin

var import_plugin = null
var export_button_index = -1
var file_export_dialog: EditorFileDialog = null
var notification_dialog: AcceptDialog = null

func _enter_tree() -> void:
	import_plugin = STF_Importer.new()
	add_scene_format_importer_plugin(import_plugin, true)
	
	get_export_as_menu().add_item("STF")
	export_button_index = get_export_as_menu().item_count - 1
	get_export_as_menu().set_item_metadata(export_button_index, _open_export_dialog)
	
	file_export_dialog = EditorFileDialog.new()
	get_editor_interface().get_base_control().add_child(file_export_dialog)
	file_export_dialog.file_selected.connect(_export_dialog_action)
	file_export_dialog.set_title("Export STF File")
	file_export_dialog.set_file_mode(EditorFileDialog.FILE_MODE_SAVE_FILE)
	file_export_dialog.set_access(EditorFileDialog.ACCESS_FILESYSTEM)
	file_export_dialog.clear_filters()
	file_export_dialog.add_filter("*.stf")
	file_export_dialog.set_title("Export Scene to STF File")
	
	notification_dialog = AcceptDialog.new()


func _exit_tree() -> void:
	file_export_dialog.queue_free()
	notification_dialog.queue_free()

	if(import_plugin):
		remove_scene_format_importer_plugin(import_plugin)
		import_plugin = null

	if(export_button_index >= 0):
		get_export_as_menu().remove_item(export_button_index)


func _open_export_dialog():
	if not get_tree().get_edited_scene_root():
		notification_dialog.dialog_text = "No Scene to export!"
		notification_dialog.ok_button_text = "OK"
		get_editor_interface().popup_dialog_centered(notification_dialog)
		return

	file_export_dialog.set_current_file(get_tree().get_edited_scene_root().scene_file_path.get_file().get_basename() + ".stf")
	file_export_dialog.popup_centered_ratio()

func _export_dialog_action(path: String):
	STF_Exporter.export(path, get_tree())
