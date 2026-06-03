class_name StandardMaterial3D_Converter
extends STF_Material_Converter

func _get_material_name() -> String:
	return "StandardMaterial3D"

func _get_priority() -> int:
	return 1

func _convert(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> STF_Handler.ImportResult:
	var ret = StandardMaterial3D.new()
	ret.resource_name = json_resource.get("name", "STF " + _get_material_name())
	var stf_resource := _set_stf_meta(STF_Resource.new(context, stf_id, json_resource, "data"), ret)

	if("properties" in json_resource):
		for key in json_resource["properties"]:
			var property: Dictionary = json_resource["properties"][key]
			var type = property.get("type")
			var values = property.get("values", [])

			if(key == "albedo.texture" && type == "image" && len(values) == 1 && values[0].get("image") != null):
				ret.albedo_texture = _get_texture(stf_resource, stf_resource.import(values[0].get("image")))

			elif(key == "roughness.texture" && type == "image" && len(values) == 1 && values[0].get("image") != null):
				ret.roughness_texture = _get_texture(stf_resource, stf_resource.import(values[0].get("image")))

			elif(key == "metallic.texture" && type == "image" && len(values) == 1 && values[0].get("image") != null):
				ret.metallic = 1
				ret.metallic_texture = _get_texture(stf_resource, stf_resource.import(values[0].get("image")))

			elif(key == "normal.texture" && type == "image" && len(values) == 1 && values[0].get("image") != null):
				ret.normal_enabled = true
				ret.normal_texture = _get_texture(stf_resource, stf_resource.import(values[0].get("image")))

	return STF_Handler.ImportResult.new(ret)

