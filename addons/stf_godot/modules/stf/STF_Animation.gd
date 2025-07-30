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

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var ret = Animation.new()
	ret.resource_name = json_resource.get("name", "STF Animation")

	ret.set_meta("stf_id", stf_id)
	var stf_meta := {"stf_name": json_resource.get("name")}
	ret.set_meta("stf", stf_meta)

	# todo everything

	return ret

func _export() -> STF_ResourceExport:
	return null

