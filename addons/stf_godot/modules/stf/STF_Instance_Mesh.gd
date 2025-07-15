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

	var stf_meta := {"stf_instance_id": stf_id, "stf_instance_name": json_resource.get("name", null)}
	ret.set_meta("stf", stf_meta)

	ret.mesh = context.import(json_resource["mesh"], "data")

	if("armature_instance" in json_resource):
		context._add_task(func():
			var armature_instance = context.import(json_resource["armature_instance"], "instance")
			if(armature_instance):
				#ret.skeleton_path = ret.get_path_to(armature_instance)
				ret.skeleton = ret.get_path_to(armature_instance)
				ret.skin = armature_instance.create_skin_from_rest_transforms()
		)

	if("blendshape_values" in json_resource):
		for i in range(min(len(json_resource["blendshape_values"]), ret.get_blend_shape_count())):
			if(json_resource["blendshape_values"][i]):
				ret.set_blend_shape_value(i, json_resource["blendshape_values"][i])
	
	for i in range(ret.get_blend_shape_count()):
		if("blendshape_values" in json_resource && len(json_resource["blendshape_values"]) > i && json_resource["blendshape_values"][i]):
			ret.set_blend_shape_value(i, json_resource["blendshape_values"][i])
		elif("blendshape_values" in ret.mesh.get_meta("stf", {}) && len(ret.mesh.get_meta("stf")["blendshape_values"]) > i):
			ret.set_blend_shape_value(i, ret.mesh.get_meta("stf")["blendshape_values"][i])

	# todo materials

	return ret

func _export() -> STF_ResourceExport:
	return null

