class_name STFEXP_Collider_Capsule
extends STF_ModuleComponent

func _get_stf_type() -> String: return "stfexp.collider.capsule"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "component"
func _get_like_types() -> Array[String]: return ["collider.capsule", "collider"]
func _get_godot_type() -> String: return "CollisionShape3D"

func _check_godot_object(godot_object: Variant) -> int:
	return 1 if godot_object is CollisionShape3D else -1

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var node: Node3D = null
	var collider_body: PhysicsBody3D = null
	if(instance_context is Skeleton3D):
		var collider_body_name: String = "STF Collider Body " + instance_context.get_bone_name(context_object)
		node = instance_context.find_child(collider_body_name)
		if(!node):
			node = BoneAttachmentUtil.ensure_attachment(instance_context, context_object)
	else:
		node = context_object

	collider_body = STF_Godot_Util.ensure_animatable_body_3d(node)

	var ret = CollisionShape3D.new()
	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Collider Capsule")
	collider_body.add_child(ret)

	var stf_resource := _set_stf_meta(STF_Resource.new(context, stf_id, json_resource, _get_stf_kind()), ret)

	ret.position = STF_TRS_Util.parse_vec3(json_resource["offset_position"])
	ret.rotation = STF_TRS_Util.parse_vec3(json_resource["offset_rotation"])

	var shape := CapsuleShape3D.new()
	shape.radius = json_resource["radius"]
	shape.height = json_resource["height"]
	ret.shape = shape

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

