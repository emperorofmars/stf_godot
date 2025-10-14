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

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is Animation else -1

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var ret = Animation.new()
	ret.resource_name = STF_Godot_Util.get_name_or_default(json_resource, "STF Animation")
	STF_Godot_Util.set_stf_meta(stf_id, json_resource, ret)

	ret.step = 1 / json_resource.get("fps", 30)

	match(json_resource.get("loop", "none")):
		"loop": ret.loop_mode = Animation.LOOP_LINEAR
		"pingpong": ret.loop_mode = Animation.LOOP_PINGPONG
		"none": ret.loop_mode = Animation.LOOP_NONE
		_: ret.loop_mode = Animation.LOOP_NONE

	var start_offset = 0
	if("range" in json_resource):
		ret.length = (json_resource["range"][1] - json_resource["range"][0]) * ret.step
		start_offset = json_resource["range"][0] * ret.step


	# Depending on user setting return rotation, position etc types, or make everything its own bezier track
	var animation_handling = context._get_import_options().get(STF_ImportOptions.AnimationHandling, 0)

	for stf_track in json_resource.get("tracks", []):
		var target: ImportAnimationPropertyResult = context.resolve_animation_path(stf_track["target"])
		if(target && target._godot_path && target._keyframe_converter):
			#print("Target: ", target._godot_path, " : ", target._track_type)
			target._keyframe_converter.call(context, ret, target._godot_path, stf_track, start_offset, animation_handling, target._value_transform_func, target._can_import_bezier)

		# todo else warn

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

