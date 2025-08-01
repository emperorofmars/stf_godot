class_name STF_Animation
extends STF_Module

func _get_stf_type() -> String:
	return "stf.animation"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "data"

func _get_like_types() -> Array[String]:
	return ["animation"]

func _get_godot_type() -> String:
	return "Animation"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var ret = Animation.new()
	ret.resource_name = json_resource.get("name", "STF Animation")

	ret.set_meta("stf_id", stf_id)
	var stf_meta := {"stf_name": json_resource.get("name")}
	ret.set_meta("stf", stf_meta)

	ret.loop_mode = Animation.LOOP_NONE if json_resource.get("loop", false) else Animation.LOOP_LINEAR
	ret.step = 1 / json_resource.get("fps", 30)

	var start_offset = 0
	if("range" in json_resource):
		ret.length = (json_resource["range"][1] - json_resource["range"][0]) * ret.step
		start_offset = json_resource["range"][0] * ret.step


	for stf_track in json_resource.get("tracks", []):
		var target: ImportAnimationPropertyResult = context.resolve_animation_path(stf_track["target"])
		if(target && target._godot_path && target._keyframe_converter):
			#print("Target: ", target._godot_path, " : ", target._track_type)
			target._keyframe_converter.call(ret, target._godot_path, stf_track["keyframes"], start_offset)

		# todo else warn

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

