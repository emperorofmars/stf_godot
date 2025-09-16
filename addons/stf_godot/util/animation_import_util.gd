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


static func import_value(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true, track_type = Animation.TYPE_VALUE):
	if(animation_handling == 2 || !can_import_bezier && animation_handling != 1): # Simplified & unbaked
		var track_index = animation.add_track(track_type)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, transform_func._callable.call(keyframe._values[0][2]) if transform_func else keyframe._values[0][2], 1)
	elif(animation_handling == 1 || !can_import_bezier): # Unbaked
		var track_index = animation.add_track(track_type)
		animation.track_set_path(track_index, target)
		var keyframe_index = 0
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			animation.track_insert_key(track_index, keyframe_index * animation.step, transform_func._callable.call(keyframe[0]) if transform_func else keyframe[0], 1)
			keyframe_index += 1
	else: # Bezier
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

static func import_blendshape(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	import_value(context, animation, target, track, start_offset, animation_handling, transform_func, can_import_bezier, Animation.TYPE_BLEND_SHAPE)


static func import_position_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	if(animation_handling == 2 || !can_import_bezier && animation_handling != 1): # Simplified & unbaked
		var track_index = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Vector3.ZERO
			for i in range(3):
				if(keyframe._values[i] != null):
					value[i] = keyframe._values[i][2]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, value, 1)
	elif(animation_handling == 1 || !can_import_bezier): # Unbaked
		var track_index = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track_index, target)
		var keyframe_index = 0
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			var value := Vector3.ZERO
			for i in range(3):
				if(keyframe[i] != null):
					value[i] = keyframe[i]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe_index * animation.step, value, 1)
			keyframe_index += 1
	else: # Bezier
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
				if(keyframe._values[i] != null && keyframe._values[i][0] && keyframe._values[i][3] == "bezier"):
					value[i] = keyframe._values[i][2]
					tangent_in[i] = keyframe._values[i][6][1] if len(keyframe._values[i]) > 6 else 0
					tangent_out[i] = keyframe._values[i][5][1]
			if(transform_func):
				value = transform_func._callable.call(value)
				tangent_in = transform_func._callable.call(tangent_in)
				tangent_out = transform_func._callable.call(tangent_out)
			for i in range(3):
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


static func import_rotation_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	if(animation_handling == 2 || !can_import_bezier && animation_handling != 1): # Simplified & unbaked
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
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, value.normalized(), 1)
	elif(animation_handling == 1 || !can_import_bezier): # Unbaked
		var track_index = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track_index, target)
		var keyframe_index = 0
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			var value := Quaternion.IDENTITY
			if(keyframe[0] != null): value.x = keyframe[0]
			if(keyframe[1] != null): value.y = keyframe[1]
			if(keyframe[2] != null): value.z = keyframe[2]
			if(keyframe[3] != null): value.w = keyframe[3]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe_index * animation.step, value.normalized(), 1)
			keyframe_index += 1
	else: # Bezier
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
				if(keyframe._values[i] != null):
					value[i] = keyframe._values[i][2]
					# todo check more keyframe interpolation types
					if(keyframe._values[i][3] == "bezier"):
						tangent_out[i] = value[i] + keyframe._values[i][5][1]
						tangent_out_weight[i] = keyframe._values[i][5][0]
						if(len(keyframe._values[i]) > 6):
							tangent_in[i] = value[i] + keyframe._values[i][6][1]
							tangent_in_weight[i] = keyframe._values[i][6][0]

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
				if(keyframe._values[i][3] == "bezier"):
					subtangent_out = Vector2(tangent_out_weight[i] * animation.step, tangent_out[i])
					if(len(keyframe._values[0]) > 6): subtangent_in = Vector2(tangent_in_weight[i] * animation.step, tangent_in[i])
				animation.bezier_track_insert_key(
					track_indices[i],
					keyframe._frame * animation.step - start_offset,
					value[i],
					subtangent_in,
					subtangent_out
				)


static func import_euler_rotation_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	if(animation_handling == 2 || !can_import_bezier && animation_handling != 1): # Simplified & unbaked
		var track_index = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Vector3.ZERO
			if(keyframe._values[0] != null): value.x = keyframe._values[0][2]
			if(keyframe._values[1] != null): value.y = keyframe._values[1][2]
			if(keyframe._values[2] != null): value.z = keyframe._values[2][2]
			if(transform_func):
				value = transform_func._callable.call(value)
			var value_quat = Quaternion.from_euler(value).normalized()
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, value_quat, 1)
	elif(animation_handling == 1 || !can_import_bezier): # Unbaked
		var track_index = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track_index, target)
		var keyframe_index = 0
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			var value := Vector3.ZERO
			if(keyframe[0] != null): value.x = keyframe[0]
			if(keyframe[1] != null): value.y = keyframe[1]
			if(keyframe[2] != null): value.z = keyframe[2]
			if(transform_func):
				value = transform_func._callable.call(value)
			var value_quat = Quaternion.from_euler(value).normalized()
			animation.track_insert_key(track_index, keyframe_index * animation.step, value_quat, 1)
			keyframe_index += 1
	else: # Bezier
		var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
		animation.track_set_path(track_indices[0], target + ":rotation:x")
		animation.track_set_path(track_indices[1], target + ":rotation:y")
		animation.track_set_path(track_indices[2], target + ":rotation:z")

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


static func import_scale_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, animation_handling = 0, transform_func: OptionalCallable = null, can_import_bezier: bool = true):
	if(animation_handling == 2 || !can_import_bezier && animation_handling != 1): # Simplified & unbaked
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
	elif(animation_handling == 1 || !can_import_bezier): # Unbaked
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
	else: # Bezier
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

