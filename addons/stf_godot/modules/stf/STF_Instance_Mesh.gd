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

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	#var ret = ImporterMeshInstance3D.new()
	var ret = MeshInstance3D.new()
	ret.name = json_resource.get("name", "STF Instance Mesh")

	var stf_meta := {"stf_instance_id": stf_id, "stf_instance_name": json_resource.get("name")}
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

	for i in range(ret.get_blend_shape_count()):
		if("blendshape_values" in json_resource && len(json_resource["blendshape_values"]) > i && json_resource["blendshape_values"][i]):
			ret.set_blend_shape_value(i, json_resource["blendshape_values"][i])
		elif("blendshape_values" in ret.mesh.get_meta("stf", {}) && len(ret.mesh.get_meta("stf")["blendshape_values"]) > i):
			ret.set_blend_shape_value(i, ret.mesh.get_meta("stf")["blendshape_values"][i])

	if("materials" in json_resource):
		for material_index in range(min(len(json_resource["materials"]), ret.mesh.get_surface_count())):
			if(json_resource["materials"][material_index]):
				var material = context.import(json_resource["materials"][material_index], "data")
				if(material):
					ret.set_surface_override_material(material_index, material)


	var animation_property_resolve_func = func (stf_path: Array, godot_object: Object):
		if(len(stf_path) < 4): return null
		var anim_target: MeshInstance3D = godot_object

		# todo depending on user setting return rotation/position etc types, or make everything its own bezier track
		var blendshape_converter = func(animation: Animation, target: String, keyframes: Array, start_offset: float):
			var track_index = animation.add_track(Animation.TYPE_BLEND_SHAPE)
			animation.track_set_path(track_index, target)
			for keyframe in keyframes:
				var frame = keyframe["frame"]
				var value: float = 0
				if(typeof(keyframe["values"][0][0]) == TYPE_BOOL):
					value = keyframe["values"][0][1]
				else:
					value = keyframe["values"][0][0] # todo legacy, remove at some point
				animation.track_insert_key(track_index, frame * animation.step - start_offset, value, 1)

		match stf_path[1]:
			"blendshape":
				var blendshape_name = stf_path[2]
				match stf_path[3]:
					"value": return ImportAnimationPropertyResult.new(anim_target.owner.get_path_to(anim_target).get_concatenated_names() + ":" + blendshape_name, blendshape_converter)
		return null

	return ImportResult.new(ret, OptionalCallable.new(animation_property_resolve_func))

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

