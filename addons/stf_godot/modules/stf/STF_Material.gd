class_name STF_Material
extends STF_Module

func _get_stf_type() -> String:
	return "stf.material"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "data"

func _get_like_types() -> Array[String]:
	return ["material"]

func _get_godot_type() -> String:
	return "StandardMaterial3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is StandardMaterial3D else -1


func __get_texture(image: Image) -> Texture2D:
	if(not image): return null
	if("processed" in image.get_meta("stf") && len(image.get_meta("stf")["processed"]) > 0):
		return image.get_meta("stf")["processed"][0]
	else:
		return ImageTexture.create_from_image(image)

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	# todo make target materials hot-loadable & select target material/shader based on best match or user override

	var ret = StandardMaterial3D.new()
	ret.resource_name = json_resource.get("name", "STF Material")
	STF_Godot_Util.set_stf_meta(stf_id, json_resource, ret)

	if("properties" in json_resource):
		for key in json_resource["properties"]:
			var property: Dictionary = json_resource["properties"][key]
			var type = property.get("type")
			var values = property.get("values", [])

			if(key == "albedo.texture" && type == "image" && len(values) == 1):
				ret.albedo_texture = __get_texture(context.import(values[0].get("image")))

			elif(key == "roughness.texture" && type == "image" && len(values) == 1):
				ret.roughness_texture = __get_texture(context.import(values[0].get("image")))

			elif(key == "metallic.texture" && type == "image" && len(values) == 1):
				ret.metallic = 1
				ret.metallic_texture = __get_texture(context.import(values[0].get("image")))
			
			elif(key == "normal.texture" && type == "image" && len(values) == 1):
				ret.normal_enabled = true
				ret.normal_texture = __get_texture(context.import(values[0].get("image")))

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

