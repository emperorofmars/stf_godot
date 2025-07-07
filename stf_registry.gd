class_name STF_Registry

const _default_stf_modules: Array[STF_Module] = []
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

static func get_modules_by_stf_type() -> Dictionary[String, STF_Module]:
	var ret: Dictionary[String, STF_Module] = {}
	for module in _default_stf_modules:
		ret[module.get_stf_type()] = module
	return ret

static func get_modules_by_godot_type() -> Dictionary[String, STF_Module]:
	var ret: Dictionary[String, STF_Module] = {}
	for module in _default_stf_modules:
		ret[module.get_godot_type()] = module
	return ret
