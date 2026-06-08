class_name STF_Material_Registry
## Register [STF_Material_Converter] implementations here.


static var _stf_materials: Array[STF_Material_Converter] = []


static func register_material(material_converter: STF_Material_Converter):
	if(_stf_materials.find(material_converter) < 0):
		_stf_materials.append(material_converter)
	else:
		printerr("STF Material Converter '%s' is already registered!" % str(material_converter))

static func unregister_material(material_converter: STF_Material_Converter):
	var index = _stf_materials.find(material_converter)
	if(index >= 0):
		_stf_materials.remove_at(index)
	else:
		printerr("Cannot remove STF Material Converter. '%s' is not registered!" % str(material_converter))


static func get_default_material_converters() -> Array[STF_Material_Converter]:
	return [
		StandardMaterial3D_Converter.new()
	]


static func match_material(target_shader_name: String, style_hints: Array) -> STF_Material_Converter:
	var material_converters = get_default_material_converters() + _stf_materials

	# Filter by target material name
	if(target_shader_name):
		material_converters = material_converters.filter(func(converter: STF_Material_Converter): converter._get_shader_name().to_lower() == target_shader_name.to_lower())

	# Filter by highest style-hint match
	if(len(style_hints) > 0):
		var matches: Dictionary[int, Array] = {}
		var best_match_score = -1
		for converter in material_converters:
			var score = 0
			for stf_hint in style_hints:
				for mat_hint in converter._get_style_hints():
					if(stf_hint.to_lower() == mat_hint.to_lower()):
						score += 1
						break
			if(score > best_match_score):
				best_match_score = score

			if(!matches.has(score)): matches[score] = []
			matches[score].append(converter)
		if(best_match_score > 0):
			material_converters = matches[best_match_score]

	# If more than one material remains, select the highest priority one
	var best_match: STF_Material_Converter = null
	for converter in material_converters:
		if(!best_match or converter._get_priority() > best_match._get_priority()):
			best_match = converter

	return best_match
