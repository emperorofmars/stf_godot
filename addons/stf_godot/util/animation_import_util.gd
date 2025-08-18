class_name STFAnimationImportUtil


class STFKeyframe:
	var _frame: float
	var _values: Array[Variant]
	func _init(frame: float, values: Array[Variant]) -> void:
		_frame = frame
		_values = values

static func arrange_unbaked_keyframes(track: Dictionary) -> Array[STFKeyframe]:
	var subtracks = track.get("subtracks", [])
	var len = -1;
	for subtrack in subtracks:
		if(subtrack && len(subtrack["keyframes"]) > len):
			len = len(subtrack["keyframes"])
	if(len <= 0): return []

	var keyframes: Array[STFKeyframe] = []
	for i in range(len):
		var value: Array[Variant] = []
		value.resize(len(subtracks))
		var frame = 0
		for subtrack_index in range(len(subtracks)):
			if(subtracks[subtrack_index] && subtracks[subtrack_index]["keyframes"][i]):
				value[subtrack_index] = subtracks[subtrack_index]["keyframes"][i]
				frame = subtracks[subtrack_index]["keyframes"][i][1]
		keyframes.append(STFKeyframe.new(frame, value))
	
	return keyframes


static func arrange_baked_keyframes(context: STF_ImportContext, track: Dictionary) -> Array[Array]:
	var subtracks = track.get("subtracks", [])
	var len = -1;
	var buffers: Array[PackedFloat32Array] = []
	for subtrack in subtracks:
		if(subtrack && "baked" in subtrack):
			var buffer := context.get_buffer(subtrack["baked"]).to_float32_array()
			buffers.append(context.get_buffer(subtrack["baked"]).to_float32_array())
			if(len(buffer) > len):
				len = len(buffer)
		else:
			buffers.append(null)
	if(len <= 0): return []

	var keyframes: Array[Array] = []
	for i in range(len):
		var subkeyframe = []
		for buffer in buffers:
			subkeyframe.append(buffer[i] if buffer else 0)
		keyframes.append(subkeyframe)
	
	return keyframes


static func import_value(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, use_baked = false, simplify = false, transform_func: STF_Module.OptionalCallable = null, can_import_bezier: bool = true, track_type = Animation.TYPE_VALUE):
	if(simplify || !can_import_bezier && !use_baked):
		var track_index = animation.add_track(track_type)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, transform_func._callable.call(keyframe._values[0][2]) if transform_func else keyframe._values[0][2], 1)
	elif(use_baked || !can_import_bezier):
		var track_index = animation.add_track(track_type)
		animation.track_set_path(track_index, target)
		var keyframe_index = 0
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			animation.track_insert_key(track_index, keyframe_index * animation.step, transform_func._callable.call(keyframe[0]) if transform_func else keyframe[0], 1)
			keyframe_index += 1
	else:
		var track_index = animation.add_track(Animation.TYPE_BEZIER)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			# todo check more keyframe interpolation types
			var tangent_out := Vector2.ZERO
			var tangent_in := Vector2.ZERO
			if(keyframe._values[0][3] == "bezier"):
				tangent_out = Vector2(keyframe._values[0][5][0] * animation.step, -transform_func._callable.call(keyframe._values[0][5][1]) if transform_func else -keyframe._values[0][5][1])
				if(len(keyframe._values[0]) > 6): tangent_in = Vector2(keyframe._values[0][6][0] * animation.step, -transform_func._callable.call(keyframe._values[0][6][1]) if transform_func else -keyframe._values[0][6][1])
			animation.bezier_track_insert_key(
				track_index,
				keyframe._frame * animation.step - start_offset,
				transform_func._callable.call(keyframe._values[0][2]) if transform_func else keyframe._values[0][2],
				tangent_in,
				tangent_out
			)

static func import_blendshape(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, use_baked = false, simplify = false, transform_func: STF_Module.OptionalCallable = null, can_import_bezier: bool = true):
	import_value(context, animation, target, track, start_offset, use_baked, simplify, transform_func, can_import_bezier, Animation.TYPE_BLEND_SHAPE)


static func import_position_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, use_baked = false, simplify = false, transform_func: STF_Module.OptionalCallable = null, can_import_bezier: bool = true):
	if(simplify || !can_import_bezier && !use_baked):
		var track_index = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Vector3.ZERO
			for i in range(len(keyframe._values)):
				if(keyframe._values[i] != null):
					value[i] = keyframe._values[i][2]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, value, 1)
	elif(use_baked || !can_import_bezier):
		var track_index = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track_index, target)
		var keyframe_index = 0
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			var value := Vector3.ZERO
			for i in range(len(keyframe)):
				if(keyframe[i] != null):
					value[i] = keyframe[i]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe_index * animation.step, value, 1)
			keyframe_index += 1
	else:
		var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
		animation.track_set_path(track_indices[0], target + ":position:x")
		animation.track_set_path(track_indices[1], target + ":position:y")
		animation.track_set_path(track_indices[2], target + ":position:z")
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Vector3.ZERO
			var tangent_in := Vector3.ZERO
			var tangent_out := Vector3.ZERO
			for i in range(len(keyframe._values)):
				# todo check more keyframe interpolation types
				if(keyframe._values[i] != null && keyframe._values[i][0] && keyframe._values[i][3] == "bezier"):
					value[i] = keyframe._values[i][2]
					tangent_in[i] = keyframe._values[i][6][1] if len(keyframe._values[i]) > 6 else 0
					tangent_out[i] = keyframe._values[i][5][1]
			if(transform_func):
				value = transform_func._callable.call(value)
				tangent_in = transform_func._callable.call(tangent_in)
				tangent_out = transform_func._callable.call(tangent_out)
			for i in range(len(keyframe._values)):
				if(keyframe._values[i] != null && keyframe._values[i][0]):
					var subtangent_out := Vector2.ZERO
					var subtangent_in := Vector2.ZERO
					if(keyframe._values[i][3] == "bezier"):
						subtangent_out = Vector2(keyframe._values[i][5][0] * animation.step, -tangent_out[i])
						if(len(keyframe._values[0]) > 6): subtangent_in = Vector2(keyframe._values[i][6][0] * animation.step, -tangent_in[i])
					animation.bezier_track_insert_key(
						track_indices[i],
						keyframe._frame * animation.step - start_offset,
						value[i],
						subtangent_in,
						subtangent_out
					)


static func import_rotation_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, use_baked = false, simplify = false, transform_func: STF_Module.OptionalCallable = null, can_import_bezier: bool = true):
	if(simplify || !can_import_bezier && !use_baked):
		var track_index = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Quaternion.IDENTITY
			if(keyframe._values[0] != null): value.x = keyframe._values[0][2]
			if(keyframe._values[1] != null): value.y = keyframe._values[1][2]
			if(keyframe._values[2] != null): value.z = keyframe._values[2][2]
			if(keyframe._values[3] != null): value.w = keyframe._values[3][2]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, value, 1)
	elif(use_baked || !can_import_bezier):
		var track_index = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track_index, target)
		var keyframe_index = 0
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			var value = Quaternion.IDENTITY
			if(keyframe[0] != null): value.x = keyframe[0]
			if(keyframe[1] != null): value.y = keyframe[1]
			if(keyframe[2] != null): value.z = keyframe[2]
			if(keyframe[3] != null): value.w = keyframe[3]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe_index * animation.step, value, 1)
			keyframe_index += 1
	else:
		#var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
		var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
		animation.track_set_path(track_indices[0], target + ":rotation:x")
		animation.track_set_path(track_indices[1], target + ":rotation:y")
		animation.track_set_path(track_indices[2], target + ":rotation:z")
		#animation.track_set_path(track_indices[3], target + ":rotation:w")
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Quaternion.IDENTITY
			var tangent_out := Quaternion.IDENTITY
			var tangent_out_weight := Vector4.ZERO
			var tangent_in := Quaternion.IDENTITY
			var tangent_in_weight := Vector4.ZERO

			# Why can't a Quaternion be indexed?

			# todo check more keyframe interpolation types
			if(keyframe._values[0] != null):
				value.x = keyframe._values[0][2]
				if(keyframe._values[0][3] == "bezier"):
					tangent_out.x = value.x + keyframe._values[0][5][1]
					tangent_out_weight.x = keyframe._values[0][5][0]
					if(len(keyframe._values[0]) > 6):
						tangent_in.x = value.x + keyframe._values[0][6][1]
						tangent_in_weight.x = keyframe._values[0][6][0]
			if(keyframe._values[1] != null):
				value.y = keyframe._values[1][2]
				if(keyframe._values[1][3] == "bezier"):
					tangent_out.y = value.y + keyframe._values[1][5][1]
					tangent_out_weight.y = keyframe._values[1][5][0]
					if(len(keyframe._values[1]) > 6):
						tangent_in.y = value.y + keyframe._values[1][6][1]
						tangent_in_weight.y = keyframe._values[1][6][0]
			if(keyframe._values[2] != null):
				value.z = keyframe._values[2][2]
				if(keyframe._values[2][3] == "bezier"):
					tangent_out.z = value.z + keyframe._values[2][5][1]
					tangent_out_weight.z = keyframe._values[2][5][0]
					if(len(keyframe._values[2]) > 6):
						tangent_in.z = value.z + keyframe._values[2][6][1]
						tangent_in_weight.z = keyframe._values[2][6][0]
			if(keyframe._values[3] != null): 
				value.w = keyframe._values[3][2]
				if(keyframe._values[3][3] == "bezier"):
					tangent_out_weight.w = keyframe._values[3][5][0]
					tangent_out.w = value.w + keyframe._values[3][5][1]
					if(len(keyframe._values[3]) > 6):
						tangent_in.w = value.w + keyframe._values[3][6][1]
						tangent_in_weight.w = keyframe._values[3][6][0]

			if(transform_func):
				value = transform_func._callable.call(value)
				tangent_out = transform_func._callable.call(tangent_out)
				tangent_in = transform_func._callable.call(tangent_in)

			# todo tangent x axis conversion from quat to euler ???
			var value_euler := value.normalized().get_euler()
			var tangent_out_euler := value_euler - tangent_out.normalized().get_euler()
			var tangent_out_weight_euler := Vector3.ONE # todo
			var tangent_in_euler := value_euler - tangent_in.normalized().get_euler()
			var tangent_in_weight_euler := -Vector3.ONE # todo

			for i in range(3):
				var subtangent_out := Vector2.ZERO
				var subtangent_in := Vector2.ZERO
				if(keyframe._values[i][3] == "bezier"):
					subtangent_out = Vector2(tangent_out_weight_euler[i] * animation.step, tangent_out_euler[i])
					if(len(keyframe._values[0]) > 6): subtangent_in = Vector2(tangent_in_weight_euler[i] * animation.step, tangent_in_euler[i])
				animation.bezier_track_insert_key(
					track_indices[i],
					keyframe._frame * animation.step - start_offset,
					value_euler[i],
					subtangent_in,
					subtangent_out
				)


static func import_scale_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, use_baked = false, simplify = false, transform_func: STF_Module.OptionalCallable = null, can_import_bezier: bool = true):
	if(simplify || !can_import_bezier && !use_baked):
		var track_index = animation.add_track(Animation.TYPE_SCALE_3D)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Vector3.ZERO
			for i in range(len(keyframe._values)):
				if(keyframe._values[i] != null):
					value[i] = keyframe._values[i][2]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, value, 1)
	elif(use_baked || !can_import_bezier):
		var track_index = animation.add_track(Animation.TYPE_SCALE_3D)
		animation.track_set_path(track_index, target)
		var keyframe_index = 0
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			var value := Vector3.ZERO
			for i in range(len(keyframe)):
				if(keyframe[i] != null):
					value[i] = keyframe[i]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe_index * animation.step, value, 1)
			keyframe_index += 1
	else:
		var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
		animation.track_set_path(track_indices[0], target + ":scale:x")
		animation.track_set_path(track_indices[1], target + ":scale:y")
		animation.track_set_path(track_indices[2], target + ":scale:z")
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Vector3.ZERO
			var tangent_in := Vector3.ZERO
			# todo check more keyframe interpolation types
			var tangent_out := Vector3.ZERO
			for i in range(len(keyframe._values)):
				if(keyframe._values[i] != null && keyframe._values[i][0] && keyframe._values[i][3] == "bezier"):
					value[i] = keyframe._values[i][2]
					tangent_in[i] = keyframe._values[i][6][1] if len(keyframe._values[i]) > 6 else 0
					tangent_out[i] = keyframe._values[i][5][1]
			if(transform_func):
				value = transform_func._callable.call(value)
				tangent_in = transform_func._callable.call(tangent_in)
				tangent_out = transform_func._callable.call(tangent_out)
			for i in range(len(keyframe._values)):
				if(keyframe._values[i] != null && keyframe._values[i][0]):
					var subtangent_out := Vector2.ZERO
					var subtangent_in := Vector2.ZERO
					if(keyframe._values[i][3] == "bezier"):
						subtangent_out = Vector2(keyframe._values[i][5][0] * animation.step, -tangent_out[i])
						if(len(keyframe._values[0]) > 6): subtangent_in = Vector2(keyframe._values[i][6][0] * animation.step, -tangent_in[i])
					animation.bezier_track_insert_key(
						track_indices[i],
						keyframe._frame * animation.step - start_offset,
						value[i],
						subtangent_in,
						subtangent_out
					)

