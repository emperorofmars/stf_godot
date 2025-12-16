class_name STFEXP_Collider_Capsule
extends STF_Module

func _get_stf_type() -> String: return "stfexp.collider.capsule"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "component"
func _get_like_types() -> Array[String]: return ["collider.capsule", "collider"]
func _get_godot_type() -> String: return "CollisionShape3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is CollisionShape3D else -1

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var node: Node3D = null
	var collider_body: PhysicsBody3D = null
	if(context_object is STF_Bone.ArmatureBone):
		var collider_body_name: String = "STF Collider Body " + context_object._armature_context._skeleton.get_bone_name(context_object._bone_index)
		node = context_object._armature_context._skeleton.find_child(collider_body_name)
		if(!node):
			node = BoneAttachmentUtil.ensure_attachment(context_object._armature_context._skeleton, context_object._bone_index)
	else:
		node = context_object

	collider_body = node.find_child("STF Collider Body", false)
	if(!collider_body):
		collider_body = AnimatableBody3D.new() # todo make this user configurable
		collider_body.name = "STF Collider Body"
		node.add_child(collider_body)

	var ret = CollisionShape3D.new()
	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Collider Capsule")
	ret.set_meta("stf_id", stf_id)
	var stf_meta_probe := {"stf_name": json_resource.get("name")}
	ret.set_meta("stf", stf_meta_probe)
	ret.set_meta("stf_lightprobe_anchor", "probe")
	collider_body.add_child(ret)

	ret.position = STF_TRS_Util.parse_vec3(json_resource["offset_position"])
	ret.rotation = STF_TRS_Util.parse_vec3(json_resource["offset_rotation"])

	var shape := CapsuleShape3D.new()
	shape.radius = json_resource["radius"]
	shape.height = json_resource["height"]
	ret.shape = shape

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

