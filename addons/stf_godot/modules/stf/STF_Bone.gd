class_name STF_Bone
extends STF_Module

func _get_stf_type() -> String:
	return "stf.bone"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "node"

func _get_like_types() -> Array[String]:
	return ["bone"]

func _get_godot_type() -> String:
	return "Bone"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var armature: Skeleton3D = context_object
	var bone_index := armature.add_bone(json_resource.get("name", stf_id))

	armature.set_bone_meta(bone_index, "stf_id", stf_id)
	armature.set_bone_meta(bone_index, "stf_name", json_resource.get("name", null))
	var stf_meta := {"stf_name": json_resource.get("name", null)}
	armature.set_bone_meta(bone_index, "stf", stf_meta)

	var rest_pose = Transform3D(Basis(STF_TRS_Util.parse_quat(json_resource["rotation"]).normalized()), STF_TRS_Util.parse_vec3(json_resource["translation"]))
	armature.set_bone_rest(bone_index, rest_pose)

	for child_id in json_resource.get("children", []):
		var child_index = context.import(child_id, "node", context_object)
		armature.set_bone_parent(child_index, bone_index)
		armature.set_bone_rest(child_index, rest_pose.inverse() * armature.get_bone_rest(child_index))

	var animation_property_resolve_func = func (stf_path: Array, godot_object: Object):
		if(len(stf_path) < 2): return null
		var node: Skeleton3D = godot_object
		var anim_bone_index = -1
		for i in range(node.get_bone_count()):
			if(node.get_bone_meta(i, "stf_id") == stf_path[0]):
				anim_bone_index = i
				break

		# todo depending on user setting return rotation/position etc types, or make everything its own bezier track
		var simplify_animations = context._get_import_options().get("stf/simplify_animations", false)

		var converter_func_translation = func(animation: Animation, target: String, keyframes: Array, start_offset: float):
			#if(simplify_animations):
			var track_index = animation.add_track(Animation.TYPE_POSITION_3D)
			animation.track_set_path(track_index, target)
			for keyframe in keyframes:
				var frame = keyframe["frame"]
				var value := Vector3.ZERO
				for i in range(3):
					if(keyframe["values"][i]):
						value[i] = keyframe["values"][i][0]
				var relative_pose = armature.get_bone_rest(bone_index)
				value += relative_pose.origin
				animation.track_insert_key(track_index, frame * animation.step - start_offset, value, 1)
			# Godot why
			"""else:
				var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
				animation.track_set_path(track_indices[0], target + ":position:x")
				animation.track_set_path(track_indices[1], target + ":position:y")
				animation.track_set_path(track_indices[2], target + ":position:z")
				for keyframe in keyframes:
					var frame = keyframe["frame"]
					var value := Vector3.ZERO
					for i in range(3):
						if(keyframe["values"][i]):
							value[i] = keyframe["values"][i][0]
					var relative_pose = armature.get_bone_rest(bone_index)
					value += relative_pose.origin
					for i in range(3):
						animation.bezier_track_insert_key(track_indices[i], frame * animation.step - start_offset, value[i], Vector2(keyframe["values"][i][1], keyframe["values"][i][2]), Vector2(keyframe["values"][i][3], keyframe["values"][i][4]))"""


		var converter_func_rotation = func(animation: Animation, target: String, keyframes: Array, start_offset: float):
			var track_index = animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track_index, target)
			for keyframe in keyframes:
				var frame = keyframe["frame"]
				var value_tmp := Vector4.ZERO
				for i in range(len(keyframe["values"])):
					if(keyframe["values"][i]):
						value_tmp[i] = keyframe["values"][i][0]
				var value = Quaternion.IDENTITY
				value.x = value_tmp[0]
				value.y = value_tmp[1]
				value.z = value_tmp[2]
				value.w = value_tmp[3]
				var relative_pose = armature.get_bone_rest(bone_index)
				value = relative_pose.basis.get_rotation_quaternion() * value
				animation.track_insert_key(track_index, frame * animation.step - start_offset, value.normalized(), 1)

		var converter_func_scale = func(animation: Animation, target: String, keyframes: Array, start_offset: float):
			var track_index = animation.add_track(Animation.TYPE_SCALE_3D)
			animation.track_set_path(track_index, target)
			for keyframe in keyframes:
				var frame = keyframe["frame"]
				var value := Vector3.ONE
				for i in range(len(keyframe["values"])):
					if(keyframe["values"][i]):
						value[i] = keyframe["values"][i][0]
				animation.track_insert_key(track_index, frame * animation.step - start_offset, value, 1)

		if(anim_bone_index >= 0):
			match stf_path[1]: # todo no clue if this is how it works
				"t": return ImportAnimationPropertyResult.new(node.get_bone_name(anim_bone_index), converter_func_translation)
				"r": return ImportAnimationPropertyResult.new(node.get_bone_name(anim_bone_index), converter_func_rotation)
				"s": return ImportAnimationPropertyResult.new(node.get_bone_name(anim_bone_index), converter_func_scale)
				"components":
					return null # todo
		return null

	return ImportResult.new(bone_index, OptionalCallable.new(animation_property_resolve_func))

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null
