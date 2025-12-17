class_name STFAnimationImportUtil


class STFSubtrackKeyframe:
	var _source_of_truth: bool
	var _value: float
	var _interpolation_type: String
	var _handle_type: String
	var _handle_right: Array
	var _handle_left: Array

	static func from_stf_keyframe(values: Array[Variant]) -> STFSubtrackKeyframe:
		var ret = STFSubtrackKeyframe.new()
		ret._source_of_truth = values[0]
		ret._value = values[1]
		ret._interpolation_type = values[2]
		if(ret._interpolation_type == "bezier"):
			ret._handle_type = values[3]
			ret._handle_right = values[4]
			if(len(values) > 5):
				ret._handle_left = values[5]
		elif(ret._interpolation_type in ["constant", "quadratic", "cubic"]):
			if(len(values) > 4):
				ret._handle_left = values[4]
		return ret

	static func from_baked(value: float) -> STFSubtrackKeyframe:
		var ret = STFSubtrackKeyframe.new()
		ret._source_of_truth = false
		ret._value = value
		ret._interpolation_type = "baked"
		return ret


class STFKeyframe:
	var _frame: float
	var _subframes: Array[STFSubtrackKeyframe]

	static func from_stf_keyframe(frame: float, values: Array[Variant]) -> STFKeyframe:
		var ret = STFKeyframe.new()
		ret._frame = frame
		for v in values:
			ret._subframes.append(STFSubtrackKeyframe.from_stf_keyframe(v))
		return ret

	static func from_baked(frame: float, values: Array[Variant]) -> STFKeyframe:
		var ret = STFKeyframe.new()
		ret._frame = frame
		for v in values:
			ret._subframes.append(STFSubtrackKeyframe.from_baked(v))
		return ret


static func arrange_unbaked_keyframes(track: Dictionary) -> Array[STFKeyframe]:
	var subtracks = track.get("subtracks", [])
	var timepoints = track.get("timepoints", [])
	var len = -1;
	for subtrack in subtracks:
		if(subtrack && len(subtrack["keyframes"]) > len):
			len = len(subtrack["keyframes"])
	if(len <= 0 || len(timepoints) == 0): return []

	var keyframes: Array[STFKeyframe] = []
	for i in range(len(timepoints)):
		var value: Array[Variant] = []
		value.resize(len(subtracks))
		for subtrack_index in range(len(subtracks)):
			if(subtracks[subtrack_index] && subtracks[subtrack_index]["keyframes"][i]):
				value[subtrack_index] = subtracks[subtrack_index]["keyframes"][i]
		keyframes.append(STFKeyframe.from_stf_keyframe(timepoints[i], value))

	return keyframes


static func arrange_baked_keyframes(context: STF_ImportContext, track: Dictionary) -> Array[STFKeyframe]:
	var subtracks = track.get("subtracks", [])
	var len = -1;
	var buffers: Array[PackedFloat32Array] = []
	for subtrack in subtracks:
		var buffer = null
		if(subtrack && subtrack is Dictionary && "baked" in subtrack):
			buffer = context.get_buffer(subtrack["baked"]).to_float32_array()
		elif(subtrack && subtrack is String):
			buffer = context.get_buffer(subtrack).to_float32_array()

		buffers.append(buffer)
		if(buffer && len(buffer) > len):
			len = len(buffer)
	if(len <= 0): return []

	var keyframes: Array[STFKeyframe] = []
	for i in range(len):
		var subkeyframes = []
		for buffer in buffers:
			subkeyframes.append(buffer[i] if buffer else 0)
		keyframes.append(STFKeyframe.from_baked(i, subkeyframes))

	return keyframes


static func determine_handling_method(animation_handling: int, can_import_bezier: bool, stf_track: Dictionary) -> int:
	# Fully baked track
	if(stf_track.get("track_baked", false) == true):
		return 2
	# Unbaked simplified keyframes
	elif(animation_handling == 2 || stf_track.get("interpolation") not in ["bezier", "mixed"]):
		return 2
	# Baked keyframes
	elif(animation_handling == 1 || !can_import_bezier):
		return 1
	# Bezier or Mixed keyframes
	else:
		return 0


static func create_track(animation: Animation, target: String, stf_track: Dictionary, track_type: int) -> int:
	var track_index := animation.add_track(track_type)
	animation.track_set_path(track_index, target)
	match stf_track.get("interpolation"):
		"linear": animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)
		"constant": animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_NEAREST)
		_: animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_CUBIC)
	return track_index


static func import_value(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling: int = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true, track_type = Animation.TYPE_VALUE):
	var method = determine_handling_method(animation_handling, can_import_bezier, track)
	match(method):
		2, 1: # Unbaked Simplified or Baked
			var track_index := create_track(animation, target, track, track_type)
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track) if method == 2 else STFAnimationImportUtil.arrange_baked_keyframes(context, track):
				animation.track_insert_key(track_index, keyframe._frame * animation.step - (start_offset if method == 2 else 0), transform_func._callable.call(keyframe._subframes[0]._value) if transform_func else keyframe._subframes[0]._value, 1)
		0: # Bezier or Mixed
			var track_index = animation.add_track(Animation.TYPE_BEZIER)
			animation.track_set_path(track_index, target)
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
				# todo check more keyframe interpolation types
				var tangent_out := Vector2.ZERO
				var tangent_in := Vector2.ZERO
				if(keyframe._subframes[0]._interpolation_type == "bezier"):
					tangent_out = Vector2(keyframe._subframes[0]._handle_right[0] * animation.step, -transform_func._callable.call(keyframe._subframes[0]._handle_right[1]) if transform_func else -keyframe._subframes[0]._handle_right[1])
					if(keyframe._subframes[0]._handle_left): tangent_in = Vector2(keyframe._subframes[0]._handle_left[0] * animation.step, -transform_func._callable.call(keyframe._subframes[0]._handle_left[1]) if transform_func else -keyframe._subframes[0]._handle_left[1])
				animation.bezier_track_insert_key(
					track_index,
					keyframe._frame * animation.step - start_offset,
					transform_func._callable.call(keyframe._subframes[0]._value) if transform_func else keyframe._subframes[0]._value,
					tangent_in,
					tangent_out
				)

static func import_blendshape(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	import_value(context, animation, target, track, start_offset, animation_handling, transform_func, can_import_bezier, Animation.TYPE_BLEND_SHAPE)


static func import_position_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	var method = determine_handling_method(animation_handling, can_import_bezier, track)
	match(method):
		2, 1: # Unbaked Simplified or Baked
			var track_index := create_track(animation, target, track, Animation.TYPE_POSITION_3D)
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track) if method == 2 else STFAnimationImportUtil.arrange_baked_keyframes(context, track):
				var value := Vector3.ZERO
				for i in range(3):
					if(keyframe._subframes[i] != null):
						value[i] = keyframe._subframes[i]._value
				if(transform_func):
					value = transform_func._callable.call(value)
				animation.track_insert_key(track_index, keyframe._frame * animation.step - (start_offset if method == 2 else 0), value, 1)
		0: # Bezier or Mixed
			var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
			animation.track_set_path(track_indices[0], target + ":position:x")
			animation.track_set_path(track_indices[1], target + ":position:y")
			animation.track_set_path(track_indices[2], target + ":position:z")
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
				var value := Vector3.ZERO
				var tangent_in := Vector3.ZERO
				var tangent_out := Vector3.ZERO
				for i in range(3):
					# todo check more keyframe interpolation types
					if(keyframe._subframes[i] != null && keyframe._subframes[i]._source_of_truth && keyframe._subframes[i]._interpolation_type == "bezier"):
						value[i] = keyframe._subframes[i]._value
						tangent_in[i] = keyframe._subframes[i]._handle_left[1] if keyframe._subframes[i]._handle_left else 0
						tangent_out[i] = keyframe._subframes[i]._handle_right[1]
				if(transform_func):
					value = transform_func._callable.call(value)
					tangent_in = transform_func._callable.call(tangent_in)
					tangent_out = transform_func._callable.call(tangent_out)
				for i in range(3):
					if(keyframe._subframes[i] != null && keyframe._subframes[i]._source_of_truth):
						var subtangent_out := Vector2.ZERO
						var subtangent_in := Vector2.ZERO
						if(keyframe._subframes[i]._interpolation_type == "bezier"):
							subtangent_out = Vector2(keyframe._subframes[i]._handle_right[0] * animation.step, -tangent_out[i])
							if(keyframe._subframes[0]._handle_left): subtangent_in = Vector2(keyframe._subframes[i]._handle_left[0] * animation.step, -tangent_in[i])
						animation.bezier_track_insert_key(
							track_indices[i],
							keyframe._frame * animation.step - start_offset,
							value[i],
							subtangent_in,
							subtangent_out
						)


static func import_rotation_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	var method = determine_handling_method(animation_handling, can_import_bezier, track)
	match(method):
		2, 1: # Unbaked Simplified or Baked
			var track_index := create_track(animation, target, track, Animation.TYPE_ROTATION_3D)
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track) if method == 2 else STFAnimationImportUtil.arrange_baked_keyframes(context, track):
				var value := Quaternion.IDENTITY
				if(keyframe._subframes[0] != null): value.x = keyframe._subframes[0]._value
				if(keyframe._subframes[1] != null): value.y = keyframe._subframes[1]._value
				if(keyframe._subframes[2] != null): value.z = keyframe._subframes[2]._value
				if(keyframe._subframes[3] != null): value.w = keyframe._subframes[3]._value
				if(transform_func):
					value = transform_func._callable.call(value)
				animation.track_insert_key(track_index, keyframe._frame * animation.step - (start_offset if method == 2 else 0), value.normalized(), 1)
		0: # Bezier or Mixed
			var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
			animation.track_set_path(track_indices[0], target + ":quaternion:x")
			animation.track_set_path(track_indices[1], target + ":quaternion:y")
			animation.track_set_path(track_indices[2], target + ":quaternion:z")
			animation.track_set_path(track_indices[3], target + ":quaternion:w")
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
				# Why can't a Quaternion be indexed in Godot?
				var value := Vector4(0, 0, 0, 1)
				var tangent_out := Vector4(0, 0, 0, 1)
				var tangent_out_weight := Vector4.ZERO
				var tangent_in := Vector4(0, 0, 0, 1)
				var tangent_in_weight := Vector4.ZERO

				for i in range(4):
					if(keyframe._subframes[i] != null):
						value[i] = keyframe._subframes[i]._value
						# todo check more keyframe interpolation types
						if(keyframe._subframes[i]._interpolation_type == "bezier"):
							tangent_out[i] = value[i] + keyframe._subframes[i]._handle_right[1]
							tangent_out_weight[i] = keyframe._subframes[i]._handle_right[0]
							if(keyframe._subframes[i]._handle_left):
								tangent_in[i] = value[i] + keyframe._subframes[i]._handle_left[1]
								tangent_in_weight[i] = keyframe._subframes[i]._handle_left[0]

				var value_quat := Quaternion(value.x, value.y, value.z, value.w).normalized()
				var tangent_out_quat := Quaternion(tangent_out.x, tangent_out.y, tangent_out.z, tangent_out.w).normalized()
				var tangent_in_quat := Quaternion(tangent_in.x, tangent_in.y, tangent_in.z, tangent_in.w).normalized()

				if(transform_func):
					value_quat = transform_func._callable.call(value_quat)
					tangent_out_quat = transform_func._callable.call(tangent_out_quat)
					tangent_in_quat = transform_func._callable.call(tangent_in_quat)

				value = Vector4(value_quat.x, value_quat.y, value_quat.z, value_quat.w)
				tangent_out = Vector4(tangent_out_quat.x, tangent_out_quat.y, tangent_out_quat.z, tangent_out_quat.w)
				tangent_in = Vector4(tangent_in_quat.x, tangent_in_quat.y, tangent_in_quat.z, tangent_in_quat.w)

				for i in range(4):
					var subtangent_out := Vector2.ZERO
					var subtangent_in := Vector2.ZERO
					if(keyframe._subframes[i]._interpolation_type == "bezier"):
						subtangent_out = Vector2(tangent_out_weight[i] * animation.step, tangent_out[i])
						if(keyframe._subframes[0]._handle_left): subtangent_in = Vector2(tangent_in_weight[i] * animation.step, tangent_in[i])
					animation.bezier_track_insert_key(
						track_indices[i],
						keyframe._frame * animation.step - start_offset,
						value[i],
						subtangent_in,
						subtangent_out
					)


static func import_euler_rotation_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	var method = determine_handling_method(animation_handling, can_import_bezier, track)
	match(method):
		2, 1: # Unbaked Simplified or Baked
			var track_index := create_track(animation, target, track, Animation.TYPE_ROTATION_3D)
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track) if method == 2 else STFAnimationImportUtil.arrange_baked_keyframes(context, track):
				var value := Vector3.ZERO
				if(keyframe._subframes[0] != null): value.x = keyframe._subframes[0]._value
				if(keyframe._subframes[1] != null): value.y = keyframe._subframes[1]._value
				if(keyframe._subframes[2] != null): value.z = keyframe._subframes[2]._value
				if(transform_func):
					value = transform_func._callable.call(value)
				var value_quat = Quaternion.from_euler(value).normalized()
				animation.track_insert_key(track_index, keyframe._frame * animation.step - (start_offset if method == 2 else 0), value_quat, 1)
		0: # Bezier or Mixed
			var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
			animation.track_set_path(track_indices[0], target + ":rotation:x")
			animation.track_set_path(track_indices[1], target + ":rotation:y")
			animation.track_set_path(track_indices[2], target + ":rotation:z")

			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
				var value := Vector3.ZERO
				var tangent_in := Vector3.ZERO
				var tangent_out := Vector3.ZERO
				for i in range(len(keyframe._subframes)):
					# todo check more keyframe interpolation types
					if(keyframe._subframes[i] != null && keyframe._subframes[i]._source_of_truth && keyframe._subframes[i]._interpolation_type == "bezier"):
						value[i] = keyframe._subframes[i]._value
						tangent_in[i] = keyframe._subframes[i]._handle_left[1] if keyframe._subframes[i]._handle_left else 0
						tangent_out[i] = keyframe._subframes[i]._handle_right[1]
				if(transform_func):
					value = transform_func._callable.call(value)
					tangent_in = transform_func._callable.call(tangent_in)
					tangent_out = transform_func._callable.call(tangent_out)
				for i in range(len(keyframe._subframes)):
					if(keyframe._subframes[i] != null && keyframe._subframes[i]._source_of_truth):
						var subtangent_out := Vector2.ZERO
						var subtangent_in := Vector2.ZERO
						if(keyframe._subframes[i]._interpolation_type == "bezier"):
							subtangent_out = Vector2(keyframe._subframes[i]._handle_right[0] * animation.step, -tangent_out[i])
							if(keyframe._subframes[0]._handle_left): subtangent_in = Vector2(keyframe._subframes[i]._handle_left[0] * animation.step, -tangent_in[i])
						animation.bezier_track_insert_key(
							track_indices[i],
							keyframe._frame * animation.step - start_offset,
							value[i],
							subtangent_in,
							subtangent_out
						)


static func import_scale_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	var method = determine_handling_method(animation_handling, can_import_bezier, track)
	match(method):
		2, 1: # Unbaked Simplified or Baked
			var track_index := create_track(animation, target, track, Animation.TYPE_SCALE_3D)
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track) if method == 2 else STFAnimationImportUtil.arrange_baked_keyframes(context, track):
				var value := Vector3.ZERO
				for i in range(len(keyframe._subframes)):
					if(keyframe._subframes[i] != null):
						value[i] = keyframe._subframes[i]._value
				if(transform_func):
					value = transform_func._callable.call(value)
				animation.track_insert_key(track_index, keyframe._frame * animation.step - (start_offset if method == 2 else 0), value, 1)
		0: # Bezier or Mixed
			var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
			animation.track_set_path(track_indices[0], target + ":scale:x")
			animation.track_set_path(track_indices[1], target + ":scale:y")
			animation.track_set_path(track_indices[2], target + ":scale:z")
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
				var value := Vector3.ZERO
				var tangent_in := Vector3.ZERO
				# todo check more keyframe interpolation types
				var tangent_out := Vector3.ZERO
				for i in range(len(keyframe._subframes)):
					if(keyframe._subframes[i] != null && keyframe._subframes[i]._source_of_truth && keyframe._subframes[i]._interpolation_type == "bezier"):
						value[i] = keyframe._subframes[i]._value
						tangent_in[i] = keyframe._subframes[i]._handle_left[1] if len(keyframe._subframes[i]._handle_left) > 6 else 0
						tangent_out[i] = keyframe._subframes[i]._handle_right[1]
				if(transform_func):
					value = transform_func._callable.call(value)
					tangent_in = transform_func._callable.call(tangent_in)
					tangent_out = transform_func._callable.call(tangent_out)
				for i in range(len(keyframe._subframes)):
					if(keyframe._subframes[i] != null && keyframe._subframes[i]._source_of_truth):
						var subtangent_out := Vector2.ZERO
						var subtangent_in := Vector2.ZERO
						if(keyframe._subframes[i]._interpolation_type == "bezier"):
							subtangent_out = Vector2(keyframe._subframes[i]._handle_right[0] * animation.step, -tangent_out[i])
							if(keyframe._subframes[0]._handle_left): subtangent_in = Vector2(keyframe._subframes[i]._handle_left[0] * animation.step, -tangent_in[i])
						animation.bezier_track_insert_key(
							track_indices[i],
							keyframe._frame * animation.step - start_offset,
							value[i],
							subtangent_in,
							subtangent_out
						)


static func import_color(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	var method = determine_handling_method(animation_handling, can_import_bezier, track)
	match(method):
		2, 1: # Unbaked Simplified or Baked
			var track_index := create_track(animation, target, track, Animation.TYPE_VALUE)
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track) if method == 2 else STFAnimationImportUtil.arrange_baked_keyframes(context, track):
				var value = []
				for sub in keyframe._subframes:
					value.append(sub._value)
				var color = Color(value[0], value[1], value[2], value[3]) if len(value) == 4 else Color(value[0], value[1], value[2])
				animation.track_insert_key(track_index, keyframe._frame * animation.step - (start_offset if method == 2 else 0), transform_func._callable.call(color) if transform_func else color, 1)
		0: # Bezier or Mixed
			var tracks = [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
			animation.track_set_path(tracks[0], target + ":r")
			animation.track_set_path(tracks[1], target + ":g")
			animation.track_set_path(tracks[2], target + ":b")
			animation.track_set_path(tracks[3], target + ":a")
			var max_index = 0
			for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
				# todo check more keyframe interpolation types
				for subframe_index in range(len(keyframe._subframes)):
					var tangent_out := Vector2.ZERO
					var tangent_in := Vector2.ZERO
					if(keyframe._subframes[subframe_index]._interpolation_type == "bezier"):
						tangent_out = Vector2(keyframe._subframes[subframe_index]._handle_right[0] * animation.step, -transform_func._callable.call(keyframe._subframes[subframe_index]._handle_right[1]) if transform_func else -keyframe._subframes[0]._handle_right[1])
						if(keyframe._subframes[subframe_index]._handle_left): tangent_in = Vector2(keyframe._subframes[subframe_index]._handle_left[0] * animation.step, -transform_func._callable.call(keyframe._subframes[subframe_index]._handle_left[1]) if transform_func else -keyframe._subframes[subframe_index]._handle_left[1])
					animation.bezier_track_insert_key(
						tracks[subframe_index],
						keyframe._frame * animation.step - start_offset,
						transform_func._callable.call(keyframe._subframes[subframe_index]._value) if transform_func else keyframe._subframes[subframe_index]._value,
						tangent_in,
						tangent_out
					)
					if(subframe_index > max_index): max_index = subframe_index
			for track_index in range(3 - max_index):
				animation.remove_track(tracks[3 - track_index])
