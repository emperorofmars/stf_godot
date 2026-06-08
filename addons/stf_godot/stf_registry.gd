class_name STF_Registry
## Register [STF_Handler] implementations here


static var _stf_handlers: Array[STF_Handler] = []


static func register_module(handler: STF_Handler):
	if(_stf_handlers.find(handler) < 0):
		_stf_handlers.append(handler)
	else:
		printerr("STF Handler '%s' is already registered!" % str(handler))

static func unregister_module(handler: STF_Handler):
	var index = _stf_handlers.find(handler)
	if(index >= 0):
		_stf_handlers.remove_at(index)
	else:
		printerr("Can not remove STF Handler. '%s' is not registered!" % str(handler))


static func get_default_handlers() -> Array[STF_Handler]:
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
		STFEXP_Constraint_Rotation.new(),
		STFEXP_Constraint_Parent.new(),
		STFEXP_Constraint_IK.new(),
		STFEXP_Lightprobe_Anchor.new(),
		STFEXP_Collider_Sphere.new(),
		STFEXP_Collider_Capsule.new(),
		STFEXP_Camera.new(),
		STFEXP_Light.new(),
		STFEXP_Instance_Text.new(),
		STFEXP_Text.new(),
		STFEXP_Node_Ethereal.new(),
		AVA_SecondaryMotion.new(),
		DEV_VRM_Springbone.new(),
		#BoneAttachment3D_TransientHandler.new(),
	]


static func get_handlers_by_stf_type() -> Dictionary[String, STF_Handler]:
	var ret: Dictionary[String, STF_Handler] = {}
	for handler in get_default_handlers():
		if(handler._get_stf_type()):
			ret[handler._get_stf_type()] = handler
	for handler in _stf_handlers:
		if(handler._get_stf_type() not in ret || handler._get_priority() > ret[handler._get_stf_type()]._get_priority()):
			ret[handler._get_stf_type()] = handler
	return ret


static func get_handlers_by_godot_type() -> Dictionary[String, Array]:
	var ret: Dictionary[String, Array] = {}
	for handler in get_default_handlers():
		__check_godot_types(ret, handler)
	for handler in _stf_handlers:
		__check_godot_types(ret, handler)
	return ret

static func __check_godot_types(ret: Dictionary[String, Array], handler: STF_Handler) -> void:
	for godot_type in handler._get_godot_types():
		if(godot_type not in ret):
			ret[godot_type] = [handler]
		else:
			ret[godot_type].append(handler)
