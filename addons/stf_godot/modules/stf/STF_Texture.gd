class_name STF_Texture
extends STF_Module

func _get_stf_type() -> String: return "stf.texture"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "data"
func _get_like_types() -> Array[String]: return ["texture"]
func _get_godot_type() -> String: return "PortableCompressedTexture2D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is PortableCompressedTexture2D else -1

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var image: Image = context_object

	#image.resize(json_resource.get("width", image.get_width()), json_resource.get("height", image.get_height()))

	if(json_resource.get("mipmaps", true)):
		image.generate_mipmaps()
	else:
		image.clear_mipmaps()

	var ret := PortableCompressedTexture2D.new()
	STF_Godot_Util.set_stf_meta(stf_id, json_resource, ret)
	
	ret.keep_compressed_buffer = true

	var compress_source = image.get_meta("stf")["data_type"]
	var quality: float = json_resource.get("quality", 0.8)

	if(quality < 0.95):
		# todo ret.set_basisu_compressor_params(uastc_level: int, rdo_quality_loss: float)
		ret.create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_BASIS_UNIVERSAL, compress_source == "normal", quality)
	else:
		ret.create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS, compress_source == "normal", quality)

	ret.size_override = Vector2(json_resource.get("width", image.get_width()), json_resource.get("height", image.get_height()))

	image.get_meta("stf")["processed"].append(ret)

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

