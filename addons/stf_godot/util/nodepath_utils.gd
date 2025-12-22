class_name NodepathUtils


static func handle_stf_source(context: STF_ImportContext, target: STF_Bone.ArmatureBone, json_resource: Dictionary, json_source: Array, error_message: String, handle_func: Callable, handle_context: Variant = null):
	if(len(json_source) == 1): # bone or node source
		var source_id = STF_Godot_Util.get_resource_reference(json_resource, json_source[0])
		var ref_bone = STF_Godot_Util.get_bone_from_skeleton(target._armature_context._skeleton, source_id)
		if(ref_bone < 0):
			context._add_task(STF_ImportContext.PROCESS_STEPS.DEFAULT, func():
				handle_func.call(CopyTransformModifier3D.REFERENCE_TYPE_NODE, target._armature_context._skeleton.get_path_to(context.import(source_id, "node")), handle_context)
			)
		else:
			handle_func.call(CopyTransformModifier3D.REFERENCE_TYPE_BONE, ref_bone, handle_context)
	elif(len(json_source) == 0): # parent of parent
		var bone_parent: int = target._armature_context._skeleton.get_bone_parent(target._bone_index)
		if(bone_parent < 0):
			context._add_task(STF_ImportContext.PROCESS_STEPS.DEFAULT, func():
				handle_func.call(CopyTransformModifier3D.REFERENCE_TYPE_NODE, "", handle_context)
			)
		else:
			var ref_bone = target._armature_context._skeleton.get_bone_parent(bone_parent)
			handle_func.call(CopyTransformModifier3D.REFERENCE_TYPE_BONE, ref_bone, handle_context)
	elif(len(json_source) == 3 && json_source[1] == "instance"): # bone of another armature
		var source_id = STF_Godot_Util.get_resource_reference(json_resource, json_source[0])
		var bone_id = STF_Godot_Util.get_resource_reference(json_resource, json_source[2])
		var _handle = func():
			var source_node = context.import(source_id, "node")
			var ref_bone = STF_Godot_Util.get_bone_from_skeleton(source_node, source_id)
			var attachment = BoneAttachmentUtil.ensure_attachment(source_node, ref_bone)
			handle_func.call(CopyTransformModifier3D.REFERENCE_TYPE_BONE, target._armature_context._skeleton.get_path_to(attachment), handle_context)
		context._add_task(STF_ImportContext.PROCESS_STEPS.DEFAULT, _handle)
	else:
		print_rich(error_message)
