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


static func get_material_converters() -> Array[STF_Material_Converter]:
	var ret: Dictionary[String, STF_Material_Converter] = {}
	for converter in get_default_material_converters():
		ret[converter._get_material_name()] = converter
	for converter in _stf_materials:
		if(converter._get_material_name() not in ret || converter._get_priority() > ret[converter._get_material_name()]._get_priority()):
			ret[converter._get_material_name()] = converter
	return ret.values()


static func match_material(json_resource: Dictionary) -> STF_Material_Converter:
	# TODO actually select best matching material
	return StandardMaterial3D_Converter.new()


