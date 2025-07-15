class_name STF_Instance_Mesh
extends STF_Module

func _get_stf_type() -> String:
	return "stf.instance.mesh"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "instance"

func _get_like_types() -> Array[String]:
	return ["instance.mesh", "instance"]

func _get_godot_type() -> String:
	return "MeshInstance3D"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	#var ret = ImporterMeshInstance3D.new()
	var ret = MeshInstance3D.new()
	ret.name = json_resource.get("name", "STF Instance Mesh")

	ret.set_meta("stf_id", stf_id)
	ret.set_meta("stf_name", json_resource.get("name", null))

	ret.mesh = context.import(json_resource["mesh"], "data")

	if("armature_instance" in json_resource):
		context._add_task(func():
			var armature_instance: Skeleton3D = context.import(json_resource["armature_instance"], "instance")
			if(armature_instance):
				#ret.skeleton_path = ret.get_path_to(armature_instance)
				ret.skeleton = ret.get_path_to(armature_instance)
				ret.skin = armature_instance.create_skin_from_rest_transforms()
		)

	if("blendshape_values" in json_resource):
		for i in range(min(len(json_resource["blendshape_values"]), ret.get_blend_shape_count())):
			ret.set_blend_shape_value(i, json_resource["blendshape_values"][i])

	# todo materials

	return ret

func _export() -> STF_ResourceExport:
	return null

