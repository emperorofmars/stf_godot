class_name STFEXP_Light
extends STF_Module

func _get_stf_type() -> String: return "stfexp.light"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "instance"
func _get_like_types() -> Array[String]: return ["light"]
func _get_godot_type() -> String: return "Light3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is Light3D else -1

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
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

	if("temperature" in json_resource):
		# reference: https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
		var temp = json_resource["temperature"] / 100
		var temp_r = 1.0 if temp <= 66 else 329.698727446 * ((temp - 60) ** -0.1332047592) / 255
		var temp_g = (99.4708025861 * log(temp) - 161.1195681661) / 255 if temp <= 66 else 288.1221695283 * ((temp - 60) ** -0.0755148492) / 255
		var temp_b = 1.0 if temp >= 66 else (0.0 if temp <= 19 else (138.5177312231 * log(temp) - 305.0447927307) / 255)
		if("color" in json_resource):
			light.light_color = Color(json_resource["color"][0] * temp_r, json_resource["color"][1] * temp_g, json_resource["color"][2] * temp_b)
		else:
			light.light_color = Color(clamp(temp_r, 0, 1), clamp(temp_g, 0, 1), clamp(temp_b, 0, 1))
	elif("color" in json_resource):
		light.light_color = Color(json_resource["color"][0], json_resource["color"][1], json_resource["color"][2])

	if("brightness" in json_resource): light.light_energy = json_resource["brightness"]

	if("shadow" in json_resource): light.shadow_enabled = json_resource["shadow"]

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

