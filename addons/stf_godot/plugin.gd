@tool
extends EditorPlugin

var import_plugin = null
var post_import_plugin = null

func _enter_tree() -> void:
	import_plugin = STF_Importer.new()
	add_scene_format_importer_plugin(import_plugin, true)
	post_import_plugin = STF_ImporterPost.new()
	add_scene_post_import_plugin(post_import_plugin)

func _exit_tree() -> void:
	if(import_plugin):
		remove_scene_format_importer_plugin(import_plugin)
		import_plugin = null
	if(post_import_plugin):
		remove_scene_post_import_plugin(post_import_plugin)
		post_import_plugin = null
