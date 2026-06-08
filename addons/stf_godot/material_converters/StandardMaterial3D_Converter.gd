class_name StandardMaterial3D_Converter
extends STF_Material_Converter

func _get_shader_name() -> String:
	return "StandardMaterial3D" # Fallback for when there are no shaders or converters for them in the Godot project

func _get_style_hints() -> Array[String]:
	return ["realistic", "pbr"]

func _get_priority() -> int:
	return 1

func _convert(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> STF_Handler.ImportResult:
	var ret = StandardMaterial3D.new()
	ret.resource_name = json_resource.get("name", "STF " + _get_shader_name())
	var stf_resource := _set_stf_meta(STF_ResourceHelper.new(context, stf_id, json_resource, "data"), ret)

	if("properties" in json_resource):
		for key in json_resource["properties"]:
			var property: Dictionary = json_resource["properties"][key]
			var type = property.get("type")
			var values = property.get("values", [])

			if(key == "albedo.texture" && type == "image" && len(values) == 1 && values[0].get("image") != null):
				var tex = stf_resource.import(values[0].get("image"))
				context._add_task(STF_ImportContext.PROCESS_STEPS.MATERIAL, func(): ret.albedo_texture = _get_texture(stf_resource, tex))

			elif(key == "roughness.texture" && type == "image" && len(values) == 1 && values[0].get("image") != null):
				var tex = stf_resource.import(values[0].get("image"))
				context._add_task(STF_ImportContext.PROCESS_STEPS.MATERIAL, func(): ret.roughness_texture = _get_texture(stf_resource, tex))

			elif(key == "metallic.texture" && type == "image" && len(values) == 1 && values[0].get("image") != null):
				var tex = stf_resource.import(values[0].get("image"))
				ret.metallic = 1
				context._add_task(STF_ImportContext.PROCESS_STEPS.MATERIAL, func(): ret.metallic_texture = _get_texture(stf_resource, tex))

			elif(key == "normal.texture" && type == "image" && len(values) == 1 && values[0].get("image") != null):
				var tex = stf_resource.import(values[0].get("image"))
				ret.normal_enabled = true
				context._add_task(STF_ImportContext.PROCESS_STEPS.MATERIAL, func(): ret.normal_texture = _get_texture(stf_resource, tex))

	return STF_Handler.ImportResult.new(ret)

