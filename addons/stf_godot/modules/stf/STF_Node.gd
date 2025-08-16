class_name STF_Node
extends STF_Module

func _get_stf_type() -> String:
	return "stf.node"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "node"

func _get_like_types() -> Array[String]:
	return ["node"]

func _get_godot_type() -> String:
	return "Node3D"


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var ret = null
	if("instance" in json_resource):
		ret = context.import(json_resource["instance"], "instance", context_object)
	else:
		ret = Node3D.new()
	ret.name = json_resource.get("name", "STF Node")

	ret.set_meta("stf_id", stf_id)
	var stf_meta = ret.get_meta("stf", {})
	stf_meta["stf_name"] = json_resource.get("name", null)
	ret.set_meta("stf", stf_meta)

	for child_id in json_resource.get("children", []):
		var child: Node3D = context.import(child_id, "node", context_object)
		ret.add_child(child)

	if("trs" in json_resource):
		ret.transform = STF_TRS_Util.parse_transform(json_resource["trs"])

	if("parent_binding" in json_resource && len(json_resource["parent_binding"]) == 3):
		context._add_task(func():
			var parent_binding: Array = json_resource["parent_binding"]
			var parent: Node = ret.get_parent()
			if(parent.is_class("Skeleton3D")):
				var bone_id = parent_binding[2]
				var bone_index = -1
				for i in range(parent.get_bone_count()):
					if(parent.get_bone_meta(i, "stf_id") == bone_id):
						bone_index = i
						break
				if(bone_index < 0): return

				var bone_attachment = BoneAttachment3D.new()
				bone_attachment.name = ret.name + "_parent_binding"
				bone_attachment.set_meta("stf", {"stf_parent_binding_for": stf_id})
				parent.add_child(bone_attachment)
				bone_attachment.bone_idx = bone_index
				parent.remove_child(ret)
				bone_attachment.add_child(ret)
				ret.transform = parent.get_bone_global_rest(bone_index).inverse() * ret.transform
		)

	if("enabled" in json_resource && json_resource["enabled"] == false):
		ret.visible = false


	# Depending on user setting return rotation, position etc types, or make everything its own bezier track
	var simplify_animations = context._get_import_options().get("stf/simplify_animations", false)

	var animation_property_resolve_func = func (stf_path: Array, godot_object: Object):
		if(len(stf_path) < 2): return null
		var node: Node3D = godot_object
		var path = node.owner.get_path_to(node).get_concatenated_names()

		var converter_func_translation = func(animation: Animation, target: String, keyframes: Array, start_offset: float):
			if(simplify_animations):
				var track_index = animation.add_track(Animation.TYPE_POSITION_3D)
				animation.track_set_path(track_index, target)
				for keyframe in keyframes:
					var frame = keyframe["frame"]
					var value := Vector3.ZERO
					for i in range(len(keyframe["values"])):
						if(keyframe["values"][i]):
							if(typeof(keyframe["values"][i][0]) == TYPE_BOOL):
								value[i] = keyframe["values"][i][1]
					animation.track_insert_key(track_index, frame * animation.step - start_offset, value, 1)
			else:
				var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
				animation.track_set_path(track_indices[0], target + ":position:x")
				animation.track_set_path(track_indices[1], target + ":position:y")
				animation.track_set_path(track_indices[2], target + ":position:z")
				for keyframe in keyframes:
					var frame = keyframe["frame"]
					var value := Vector3.ZERO
					var skip_frame = 0
					for i in range(3):
						if(keyframe["values"][i]):
							if(typeof(keyframe["values"][i][0]) == TYPE_BOOL):
								if(keyframe["values"][i][0] == false):
									skip_frame += 1
								value[i] = keyframe["values"][i][1]
					if(skip_frame == 3):
						continue
					for i in range(3):
						if(keyframe["values"][i]):
							if(typeof(keyframe["values"][i][0]) == TYPE_BOOL && len(keyframe["values"][i]) == 6):
								animation.bezier_track_insert_key(track_indices[i], frame * animation.step - start_offset, value[i], Vector2(keyframe["values"][i][2] * animation.step, keyframe["values"][i][3]), Vector2(keyframe["values"][i][4] * animation.step, keyframe["values"][i][5]))

		var converter_func_rotation = func(animation: Animation, target: String, keyframes: Array, start_offset: float):
			if(simplify_animations):
				var track_index = animation.add_track(Animation.TYPE_ROTATION_3D)
				animation.track_set_path(track_index, target)
				for keyframe in keyframes:
					var frame = keyframe["frame"]
					var value_tmp := Vector4.ZERO
					for i in range(len(keyframe["values"])):
						if(keyframe["values"][i]):
							if(typeof(keyframe["values"][i][0]) == TYPE_BOOL):
								value_tmp[i] = keyframe["values"][i][1]
					var value = Quaternion.IDENTITY
					value.x = value_tmp[0]
					value.y = value_tmp[1]
					value.z = value_tmp[2]
					value.w = value_tmp[3]
					animation.track_insert_key(track_index, frame * animation.step - start_offset, value.normalized(), 1)
			else:
				var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
				animation.track_set_path(track_indices[0], target + ":rotation:x")
				animation.track_set_path(track_indices[1], target + ":rotation:y")
				animation.track_set_path(track_indices[2], target + ":rotation:z")
				animation.track_set_path(track_indices[3], target + ":rotation:w")
				for keyframe in keyframes:
					var frame = keyframe["frame"]
					var value := Vector4.ZERO
					var skip_frame = 0
					for i in range(4):
						if(keyframe["values"][i]):
							if(typeof(keyframe["values"][i][0]) == TYPE_BOOL):
								if(keyframe["values"][i][0] == false):
									skip_frame += 1
								value[i] = keyframe["values"][i][1]
					if(skip_frame == 4):
						continue
					for i in range(4):
						if(keyframe["values"][i]):
							if(typeof(keyframe["values"][i][0]) == TYPE_BOOL && len(keyframe["values"][i]) == 6):
								animation.bezier_track_insert_key(track_indices[i], frame * animation.step - start_offset, value[i], Vector2(keyframe["values"][i][2] * animation.step, keyframe["values"][i][3]), Vector2(keyframe["values"][i][4] * animation.step, keyframe["values"][i][5]))

		var converter_func_scale = func(animation: Animation, target: String, keyframes: Array, start_offset: float):
			if(simplify_animations):
				var track_index = animation.add_track(Animation.TYPE_SCALE_3D)
				animation.track_set_path(track_index, target)
				for keyframe in keyframes:
					var frame = keyframe["frame"]
					var value := Vector3.ONE
					for i in range(len(keyframe["values"])):
						if(keyframe["values"][i]):
							if(typeof(keyframe["values"][i][0]) == TYPE_BOOL):
								value[i] = keyframe["values"][i][1]
							else:
								value[i] = keyframe["values"][i][0] # todo legacy, remove at some point
					animation.track_insert_key(track_index, frame * animation.step - start_offset, value, 1)
			else:
				var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
				animation.track_set_path(track_indices[0], target + ":scale:x")
				animation.track_set_path(track_indices[1], target + ":scale:y")
				animation.track_set_path(track_indices[2], target + ":scale:z")
				for keyframe in keyframes:
					var frame = keyframe["frame"]
					var value := Vector3.ZERO
					var skip_frame = 0
					for i in range(3):
						if(keyframe["values"][i]):
							if(typeof(keyframe["values"][i][0]) == TYPE_BOOL):
								if(keyframe["values"][i][0] == false):
									skip_frame += 1
								value[i] = keyframe["values"][i][1]
					if(skip_frame == 3):
						continue
					for i in range(3):
						if(keyframe["values"][i]):
							if(typeof(keyframe["values"][i][0]) == TYPE_BOOL && len(keyframe["values"][i]) == 6):
								animation.bezier_track_insert_key(track_indices[i], frame * animation.step - start_offset, value[i], Vector2(keyframe["values"][i][2] * animation.step, keyframe["values"][i][3]), Vector2(keyframe["values"][i][4] * animation.step, keyframe["values"][i][5]))


		match stf_path[1]:
			"t": return ImportAnimationPropertyResult.new(path, converter_func_translation)
			"r": return ImportAnimationPropertyResult.new(path, converter_func_rotation)
			"s": return ImportAnimationPropertyResult.new(path, converter_func_scale)
			"enabled": return ImportAnimationPropertyResult.new(path + ":visible", ImportAnimationPropertyResult.__default_simplified_keyframe_converter if simplify_animations else ImportAnimationPropertyResult.__default_bezier_keyframe_converter)
			"instance":
				var anim_ret := context.resolve_animation_path([ret.get_meta("stf").get("stf_instance_id")] + stf_path.slice(2)) # slightly dirty but it works
				if(anim_ret):
					return ImportAnimationPropertyResult.new(anim_ret._godot_path, anim_ret._keyframe_converter)
			"components":
				var anim_ret := context.resolve_animation_path(stf_path.slice(2))
				if(anim_ret):
					return ImportAnimationPropertyResult.new(anim_ret._godot_path, anim_ret._keyframe_converter)
		return null

	return ImportResult.new(ret, OptionalCallable.new(animation_property_resolve_func))


func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
