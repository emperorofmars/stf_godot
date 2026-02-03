class_name STFEXP_Light
extends STF_ModuleComponent

func _get_stf_type() -> String: return "stfexp.light"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "instance"
func _get_like_types() -> Array[String]: return ["light"]
func _get_godot_type() -> String: return "Light3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is Light3D else -1

func _convert_temperature(temperature: float) -> Color:
	# reference: https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
	var temp = temperature / 100
	var temp_r = 1.0 if temp <= 66 else 329.698727446 * ((temp - 60) ** -0.1332047592) / 255
	var temp_g = (99.4708025861 * log(temp) - 161.1195681661) / 255 if temp <= 66 else 288.1221695283 * ((temp - 60) ** -0.0755148492) / 255
	var temp_b = 1.0 if temp >= 66 else (0.0 if temp <= 19 else (138.5177312231 * log(temp) - 305.0447927307) / 255)
	return Color(clamp(temp_r, 0, 1), clamp(temp_g, 0, 1), clamp(temp_b, 0, 1))

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var ret: Node3D = null
	var light: Light3D = null
	match json_resource.get("light_type", "point"):
		"point":
			light = OmniLight3D.new()
			ret = light
			if("range" in json_resource): light.omni_range = json_resource["range"]

		"directional":
			light = DirectionalLight3D.new()
			light.name = STF_Godot_Util.get_name_or_default(json_resource, "STF DirectionalLight")
			ret = Node3D.new()
			ret.add_child(light)
			light.rotate_x(-PI / 2)
		"spot":
			light = SpotLight3D.new()
			light.name = STF_Godot_Util.get_name_or_default(json_resource, "STF SpotLight")
			ret = Node3D.new()
			ret.add_child(light)
			light.rotate_x(-PI / 2)
			if("range" in json_resource): light.spot_range = json_resource["range"]
			if("spot_angle" in json_resource): light.spot_angle = rad_to_deg(json_resource["spot_angle"]) / 2
		_:
			return null # invalid light type
	ret.set_meta("stf", {"stf_instance_id": stf_id, "stf_instance_name": json_resource.get("name", null)})

	var color = Color(json_resource["color"][0], json_resource["color"][1], json_resource["color"][2])
	if("temperature" in json_resource):
		var color_temp = _convert_temperature(json_resource["temperature"])
		if("color" in json_resource):
			color_temp *= color
		light.light_color = color_temp
	elif("color" in json_resource):
		light.light_color = color

	if("brightness" in json_resource): light.light_energy = json_resource["brightness"]

	if("shadow" in json_resource): light.shadow_enabled = json_resource["shadow"]

	var animation_property_resolve_func = func (stf_path: Array, godot_object: Object):
		if(len(stf_path) < 2): return null
		match stf_path[1]:
			"temperature":
				return ImportAnimationPropertyResult.new(light.owner.get_path_to(light).get_concatenated_names() + ":light_color", STFAnimationImportUtil.import_value, OptionalCallable.new(func (v): return _convert_temperature(v) * color)) # todo combine temperature and tint color somehow
			"color":
				if("temperature" in json_resource): # todo
					return ImportAnimationPropertyResult.new(light.owner.get_path_to(light).get_concatenated_names() + ":light_color_tint", STFAnimationImportUtil.import_color, OptionalCallable.new(func(v): return Color(v[0], v[1], v[2])))
				else:
					return ImportAnimationPropertyResult.new(light.owner.get_path_to(light).get_concatenated_names() + ":light_color", STFAnimationImportUtil.import_color)
			"brightness":
				return ImportAnimationPropertyResult.new(light.owner.get_path_to(light).get_concatenated_names() + ":light_energy", STFAnimationImportUtil.import_value)
			"range":
				if(light is SpotLight3D):
					return ImportAnimationPropertyResult.new(light.owner.get_path_to(light).get_concatenated_names() + ":spot_range", STFAnimationImportUtil.import_value)
				elif(light is OmniLight3D):
					return ImportAnimationPropertyResult.new(light.owner.get_path_to(light).get_concatenated_names() + ":omni_range", STFAnimationImportUtil.import_value)
			"spot_angle":
				return ImportAnimationPropertyResult.new(light.owner.get_path_to(light).get_concatenated_names() + ":spot_angle", STFAnimationImportUtil.import_value, OptionalCallable.new(func (v): return rad_to_deg(v) / 2))
		return null

	return ImportResult.new(ret, OptionalCallable.new(animation_property_resolve_func))

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

