class_name STFEXP_Curve
extends STF_Handler

func _get_stf_type() -> String: return "stfexp.curve"
func _get_priority() -> int: return 0
func _get_stf_category() -> String: return "data"
func _get_like_types() -> Array[String]: return ["curve"]

class STFEXP_Curve_Resource:
	extends Resource
	@export var curves: Array[Curve3D] = []

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var ret = STFEXP_Curve_Resource.new()
	var stf_resource := _set_stf_meta(STF_ResourceHelper.new(context, stf_id, json_resource, _get_stf_category()), ret)

	for json_spline in json_resource.get("splines", []):
		if(json_spline.get("type") == "bezier"):
			var curve = Curve3D.new()
			curve.closed = json_spline.get("cyclic", false)
			for json_point in json_spline.get("points", []):
				curve.add_point(
					Vector3(json_point["translation"][0], json_point["translation"][1], json_point["translation"][2]),
					Vector3(json_point["handle_in"][0], json_point["handle_in"][1], json_point["handle_in"][2]),
					Vector3(json_point["handle_out"][0], json_point["handle_out"][1], json_point["handle_out"][2])
				)
				curve.set_point_tilt(curve.point_count - 1, json_point["tilt"])
			ret.curves.append(curve)

	return ImportResult.new(ret, null)
