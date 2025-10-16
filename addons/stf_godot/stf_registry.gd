class_name STF_Registry
## Register STF modules here


static var _default_stf_modules: Array[STF_Module] = []
static var _stf_modules: Array[STF_Module] = []


static func register_module(module: STF_Module):
	if(_stf_modules.find(module) < 0):
		_stf_modules.append(module)
	else:
		printerr("STF Module '%s' is already registered!" % str(module))

static func unregister_module(module: STF_Module):
	var index = _stf_modules.find(module)
	if(index >= 0):
		_stf_modules.remove_at(index)
	else:
		printerr("Cannot remove STF Module. '%s' is not registered!" % str(module))


static func get_default_modules() -> Array[STF_Module]:
	return [
		STF_Prefab.new(),
		STF_Node.new(),
		STF_Instance_Armature.new(),
		STF_Armature.new(),
		STF_Bone.new(),
		STF_Instance_Mesh.new(),
		STF_Mesh.new(),
		STF_Material.new(),
		STF_Image.new(),
		STF_Texture.new(),
		STF_Animation.new(),
		STFEXP_Constraint_Twist.new(),
		STFEXP_Lightprobe_Anchor.new(),
		STFEXP_Collider_Sphere.new(),
		STFEXP_Collider_Capsule.new(),
		STFEXP_Camera.new(),
	]


static func get_modules_by_stf_type() -> Dictionary[String, STF_Module]:
	var ret: Dictionary[String, STF_Module] = {}
	for module in get_default_modules():
		ret[module._get_stf_type()] = module
	for module in _stf_modules:
		if(module._get_stf_type() not in ret || module._get_priority() > ret[module._get_stf_type()]._get_priority()):
			ret[module._get_stf_type()] = module
	return ret

static func get_modules_by_godot_type() -> Dictionary[String, Array]:
	var ret: Dictionary[String, Array] = {}
	for module in get_default_modules():
		if(module._get_godot_type() not in ret):
			ret[module._get_godot_type()] = [module]
		else:
			ret[module._get_godot_type()].append(module)
	for module in _stf_modules:
		if(module._get_godot_type() not in ret):
			ret[module._get_godot_type()] = [module]
		else:
			ret[module._get_godot_type()].append(module)
	return ret
