class_name STFEXP_Lightprobe_Anchor
extends STF_ModuleComponent

func _get_stf_type() -> String: return "stfexp.lightprobe_anchor"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "component"
func _get_like_types() -> Array[String]: return ["lightprobe_anchor"]
func _get_godot_type() -> String: return "LightmapProbe"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is LightmapProbe else -1

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var ret = LightmapProbe.new()
	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Lightprobe")
	context_object.add_child(ret)

	ret.set_meta("stf_id", stf_id)
	var stf_meta_probe := {"stf_name": json_resource.get("name")}
	ret.set_meta("stf", stf_meta_probe)
	ret.set_meta("stf_lightprobe_anchor", "probe")

	var anchor_target: Array = json_resource.get("anchor", [])
	if(len(anchor_target) == 0): return null

	context._add_task(context.PROCESS_STEPS.DEFAULT, func():
		var target_node := context.import(STF_Godot_Util.get_resource_reference(json_resource, anchor_target[0]), "node")
		var remote_parent = target_node
		if(len(anchor_target) == 3 && target_node is Skeleton3D):
			var ref_bone := STF_Godot_Util.get_bone_from_skeleton(target_node, STF_Godot_Util.get_resource_reference(json_resource, anchor_target[2]))
			remote_parent = BoneAttachmentUtil.ensure_attachment(target_node, ref_bone)

		var remoteTransform := RemoteTransform3D.new()
		remoteTransform.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Lightprobe Anchor")
		remoteTransform.set_meta("stf_id", stf_id)
		var stf_meta_anchor := {"stf_name": json_resource.get("name")}
		remoteTransform.set_meta("stf", stf_meta_anchor)
		remoteTransform.set_meta("stf_lightprobe_anchor", "anchor")
		remote_parent.add_child(remoteTransform)
		remoteTransform.remote_path = remoteTransform.get_path_to(ret)
	)

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

