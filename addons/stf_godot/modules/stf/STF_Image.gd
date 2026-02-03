class_name STF_Image
extends STF_Module

func _get_stf_type() -> String: return "stf.image"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "data"
func _get_like_types() -> Array[String]: return ["image"]
func _get_godot_type() -> String: return "Image"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is Image else -1

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var ret = Image.new()
	ret.resource_name = STF_Godot_Util.get_name_or_default(json_resource, "STF Image")
	STF_Godot_Util.set_stf_meta(stf_id, json_resource, ret)

	ret.get_meta("stf")["data_type"] = json_resource.get("data_type", "color")

	var format = json_resource["format"]

	var image_buffer = context.get_buffer(json_resource["buffer"])
	match format:
		"png": ret.load_png_from_buffer(image_buffer)
		"jpg": ret.load_jpg_from_buffer(image_buffer)
		"jpeg": ret.load_jpg_from_buffer(image_buffer)

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

