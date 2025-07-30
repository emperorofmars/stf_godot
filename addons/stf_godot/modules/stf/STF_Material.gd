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
	return "Material"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	# todo make target materials hot-loadable & select target material/shader based on best match or user override

	var ret = StandardMaterial3D.new()
	ret.resource_name = json_resource.get("name", "STF Instance Mesh")

	ret.set_meta("stf_id", stf_id)
	var stf_meta := {"stf_name": json_resource.get("name", "STF Material")}
	ret.set_meta("stf", stf_meta)

	if("properties" in json_resource):
		for key in json_resource["properties"]:
			var property: Dictionary = json_resource["properties"][key]
			var type = property.get("type")
			var values = property.get("values", [])

			if(key == "albedo.texture" && type == "image" && len(values) == 1):
				ret.albedo_texture = ImageTexture.create_from_image(context.import(values[0].get("image")))
			
			if(key == "roughness.texture" && type == "image" && len(values) == 1):
				ret.roughness_texture = ImageTexture.create_from_image(context.import(values[0].get("image")))
			
			if(key == "metallic.texture" && type == "image" && len(values) == 1):
				ret.metallic_texture = ImageTexture.create_from_image(context.import(values[0].get("image")))

	return ret

func _export() -> STF_ResourceExport:
	return null

