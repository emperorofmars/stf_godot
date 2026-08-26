class_name STFEXP_Instance_Curve
extends STF_Handler

func _get_stf_type() -> String: return "stfexp.instance.curve"
func _get_priority() -> int: return 0
func _get_stf_category() -> String: return "instance"
func _get_like_types() -> Array[String]: return ["instance.curve"]

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var curve_id := STF_Godot_Util.get_resource_reference(json_resource, json_resource["curve"])
	var curve_resource = context.import(curve_id, "data")

	if(len(curve_resource.curves) == 1):
		var ret := Path3D.new()
		ret.curve = curve_resource.curves[0]
		var stf_resource := _set_stf_meta(STF_ResourceHelper.new(context, stf_id, json_resource, _get_stf_category()), ret)
		stf_resource.register_referenced_resource(curve_id, curve_resource)
		ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Instance Curve")

		return ImportResult.new(ret, null)
	else:
		var ret := Node3D.new()
		var stf_resource := _set_stf_meta(STF_ResourceHelper.new(context, stf_id, json_resource, _get_stf_category()), ret)
		stf_resource.register_referenced_resource(curve_id, curve_resource)
		ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Instance Curve")
		for curve in curve_resource.curves:
			var path := Path3D.new()
			path.curve = curve
			ret.add_child(path)

		return ImportResult.new(ret, null)
