class_name STFEXP_Camera
extends STF_ModuleComponent

func _get_stf_type() -> String: return "stfexp.camera"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "instance"
func _get_like_types() -> Array[String]: return ["camera"]
func _get_godot_type() -> String: return "Camera3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is Camera3D else -1

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> ImportResult:
	var ret = Node3D.new()
	ret.set_meta("stf", {"stf_instance_id": stf_id, "stf_instance_name": json_resource.get("name", null)})

	var camera = Camera3D.new()
	camera.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Camera")
	STF_Godot_Util.set_stf_meta(stf_id, json_resource, camera)
	ret.add_child(camera)

	camera.rotate_x(-PI / 2)

	match json_resource.get("projection", "perspective"):
		"orthographic":
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			if("fov" in json_resource):
				camera.size = json_resource["fov"]
		_:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			if("fov" in json_resource):
				camera.fov = rad_to_deg(json_resource["fov"])

	var animation_property_resolve_func = func (stf_path: Array, godot_object: Object):
		if(len(stf_path) < 2): return null
		match stf_path[1]:
			"fov":
				if(camera.projection == Camera3D.PROJECTION_ORTHOGONAL):
					return ImportAnimationPropertyResult.new(camera.owner.get_path_to(camera).get_concatenated_names() + ":size", STFAnimationImportUtil.import_value)
				elif(camera.projection == Camera3D.PROJECTION_PERSPECTIVE):
					return ImportAnimationPropertyResult.new(camera.owner.get_path_to(camera).get_concatenated_names() + ":fov", STFAnimationImportUtil.import_value, OptionalCallable.new(func (v): return rad_to_deg(v)))
		return null

	return ImportResult.new(ret, OptionalCallable.new(animation_property_resolve_func))

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

