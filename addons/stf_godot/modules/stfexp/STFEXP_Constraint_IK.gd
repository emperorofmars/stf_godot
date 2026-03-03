class_name STFEXP_Constraint_IK
extends STF_Module

func _get_stf_type() -> String: return "stfexp.constraint.ik"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "component"
func _get_like_types() -> Array[String]: return ["constraint.ik", "constraint"]
func _get_godot_type() -> String: return "IKModifier3D"

func _check_godot_object(godot_object: Variant) -> int:
	return 1 if godot_object is IKModifier3D else -1 # todo to this properly


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	if(instance_context is not Skeleton3D):
		print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.ik[/u] with ID [u]" + stf_id + "[/u][/color]: Godot IK constraints only support bones.")
		return null
	var armature: Skeleton3D = instance_context
	var bone_index: int = context_object

	var chain_length = json_resource.get("chain_length", 1) as int

	var target: Array = json_resource.get("target", [])
	var pole: Array = json_resource.get("pole", [])

	var target_node: Node3D = null
	var pole_node: Node3D = null

	if(len(target) == 1):
		var target_id := STF_Godot_Util.get_resource_reference(json_resource, target[0])
		var target_bone := STF_Godot_Util.get_bone_from_skeleton(armature, target_id)
		if(target_bone < 0): # target is Node3D
			target_node = context.import(target_id, "node")
		else: # target is Bone, create attachment so it can be used
			var ik_meta = armature.get_bone_meta(target_bone, "stf_ik_node")
			if(ik_meta):
				target_node = armature.get_node(ik_meta)
			else:
				target_node = BoneAttachmentUtil.ensure_attachment(armature, target_bone)
	elif(len(target) == 3):
		var target_skeleton := context.import(STF_Godot_Util.get_resource_reference(json_resource, target[0]), "node")
		var target_bone := STF_Godot_Util.get_bone_from_skeleton(target_skeleton, STF_Godot_Util.get_resource_reference(json_resource, target[2]))
		target_node = BoneAttachmentUtil.ensure_attachment(target_skeleton, target_bone)

	if(len(pole) == 1):
		var pole_id := STF_Godot_Util.get_resource_reference(json_resource, pole[0])
		var pole_bone := STF_Godot_Util.get_bone_from_skeleton(armature, pole_id)
		if(pole_bone < 0): # pole is Node3D
			pole_node = context.import(pole_id, "node")
		else: # pole is Bone, create attachment so it can be used
			var ik_meta = armature.get_bone_meta(pole_bone, "stf_ik_node")
			if(ik_meta):
				pole_node = armature.get_node(ik_meta)
			else:
				pole_node = BoneAttachmentUtil.ensure_attachment(armature, pole_bone)
	elif(len(pole) == 3):
		var pole_skeleton := context.import(STF_Godot_Util.get_resource_reference(json_resource, pole[0]), "node")
		var pole_bone := STF_Godot_Util.get_bone_from_skeleton(pole_skeleton, STF_Godot_Util.get_resource_reference(json_resource, pole[2]))
		pole_node = BoneAttachmentUtil.ensure_attachment(pole_skeleton, pole_bone)

	if(chain_length == 2 and target_node and pole_node): # Can import as TwoBoneIK3D
		var ret := BoneAttachmentUtil.ensure_two_bone_ik(armature)
		var constraint_index = ret.get_setting_count()
		ret.set_setting_count(constraint_index + 1)

		ret.set_target_node(constraint_index, ret.get_path_to(target_node))
		ret.set_pole_node(constraint_index, ret.get_path_to(pole_node))

		ret.set_root_bone(constraint_index, armature.get_bone_parent(bone_index))
		ret.set_middle_bone(constraint_index, bone_index)
		ret.set_extend_end_bone(constraint_index, true)
		ret.set_use_virtual_end(constraint_index, true)
		ret.set_end_bone_direction(constraint_index, SkeletonModifier3D.BONE_DIRECTION_PLUS_Y)
		ret.set_end_bone_length(constraint_index, armature.get_bone_meta(bone_index, "stf").get("original_json", {}).get("length", 0.0))

		return ImportResult.new(ret, null)
	elif(chain_length > 1 and target_node): # Import as FABRIK3D ## TODO make this configurable to any ChainIK3D subtype
		var ret := BoneAttachmentUtil.ensure_fabrik_3d(armature)
		var constraint_index = ret.get_setting_count()
		ret.set_setting_count(constraint_index + 1)

		ret.set_target_node(constraint_index, ret.get_path_to(target_node))

		var root_bone = bone_index
		for i in range(chain_length):
			root_bone = armature.get_bone_parent(root_bone)
			if(root_bone < 0):
				# todo warn
				return null
		ret.set_root_bone(constraint_index, root_bone)

		ret.set_end_bone(constraint_index, bone_index)
		ret.set_extend_end_bone(constraint_index, true)
		ret.set_end_bone_direction(constraint_index, SkeletonModifier3D.BONE_DIRECTION_PLUS_Y)
		ret.set_end_bone_length(constraint_index, armature.get_bone_meta(bone_index, "stf").get("original_json", {}).get("length", 0.0))

		return ImportResult.new(ret, null)
	elif(chain_length == 1 and target_node): # Import as LookAtModifier3D
		var ret: = LookAtModifier3D.new()
		ret.name = "STF LookAtModifier3D"
		armature.add_child(ret)

		ret.bone = bone_index
		ret.target_node = ret.get_path_to(target_node)
		ret.forward_axis = LookAtModifier3D.BONE_AXIS_PLUS_Y
		ret.primary_rotation_axis = Vector3.AXIS_X

		return ImportResult.new(ret, null)
	else:
		# TODO handle other IK ways
		print_rich("[color=orange]Warning: Can't import resource [u]stfexp.constraint.ik[/u] with ID [u]" + stf_id + "[/u][/color]: Godot can't represent this resources settings.")
		return null


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
