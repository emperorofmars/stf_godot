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


static func import_value(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, use_baked = false, simplify = false, track_type = Animation.TYPE_VALUE, transform_func: STF_Module.OptionalCallable = null):
	if(simplify):
		var track_index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, transform_func._callable.call(keyframe._values[0][2]) if transform_func else keyframe._values[0][2], 1)
	elif(use_baked):
		var track_index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index, target)
		var keyframe_index = start_offset
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			animation.track_insert_key(track_index, keyframe_index * animation.step - start_offset, transform_func._callable.call(keyframe[0]) if transform_func else keyframe[0], 1)
			keyframe_index += 1
	else:
		var track_index = animation.add_track(Animation.TYPE_BEZIER)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			animation.bezier_track_insert_key(
				track_index,
				keyframe._frame * animation.step - start_offset,
				transform_func._callable.call(keyframe._values[2]) if transform_func else keyframe._values[2],
				Vector2(keyframe._values[0][6][0], keyframe._values[0][6][1]) if len(keyframe._values[0]) > 6 else Vector2.ZERO,
				Vector2(keyframe._values[0][5][0], keyframe._values[0][5][1])
			)

static func import_blendshape(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, use_baked = false, simplify = false, transform_func: STF_Module.OptionalCallable = null):
	import_value(context, animation, target, track, start_offset, use_baked, simplify, Animation.TYPE_BLEND_SHAPE, transform_func)


static func import_position_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, use_baked = false, simplify = false, transform_func: STF_Module.OptionalCallable = null):
	if(simplify):
		var track_index = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Vector3.ZERO
			for i in range(len(keyframe)):
				if(keyframe._values[i] != null):
					value[i] = keyframe._values[i][2]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, value, 1)
	elif(use_baked):
		var track_index = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track_index, target)
		var keyframe_index = start_offset
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			var value := Vector3.ZERO
			for i in range(len(keyframe)):
				if(keyframe[i] != null):
					value[i] = keyframe[i]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe_index * animation.step - start_offset, value, 1)
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
			for i in range(len(keyframe)):
				if(keyframe._values[i] != null && keyframe._values[i][0]):
					value[i] = keyframe._values[i][2]
					tangent_in[i] = keyframe._values[i][6][1] if len(keyframe._values[i]) > 6 else 0
					tangent_out[i] = keyframe._values[i][5][1]
			if(transform_func):
				value = transform_func._callable.call(value)
				tangent_in = transform_func._callable.call(tangent_in)
				tangent_out = transform_func._callable.call(tangent_out)
			for i in range(len(keyframe)):
				if(keyframe._values[i] != null && keyframe._values[i][0]):
					animation.bezier_track_insert_key(
						track_indices[i],
						keyframe._frame * animation.step - start_offset,
						value[i],
						Vector2(keyframe._values[i][6][0], tangent_in[i]) if len(keyframe._values[i]) > 6 else Vector2.ZERO,
						Vector2(keyframe._values[i][5][0], tangent_out[i])
					)



static func import_rotation_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, use_baked = false, simplify = false, transform_func: STF_Module.OptionalCallable = null):
	if(simplify):
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
	elif(use_baked):
		var track_index = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track_index, target)
		var keyframe_index = start_offset
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			var value = Quaternion.IDENTITY
			if(keyframe[0] != null): value.x = keyframe[0]
			if(keyframe[1] != null): value.y = keyframe[1]
			if(keyframe[2] != null): value.z = keyframe[2]
			if(keyframe[3] != null): value.w = keyframe[3]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe_index * animation.step - start_offset, value, 1)
			keyframe_index += 1
	else:
		var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
		animation.track_set_path(track_indices[0], target + ":rotation:x")
		animation.track_set_path(track_indices[1], target + ":rotation:y")
		animation.track_set_path(track_indices[2], target + ":rotation:z")
		animation.track_set_path(track_indices[4], target + ":rotation:w")
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			for i in range(len(keyframe)):
				if(keyframe._values[i] != null && keyframe._values[i][0]):
					animation.bezier_track_insert_key(
						track_indices[i],
						keyframe._frame * animation.step - start_offset,
						keyframe._values[i][2],
						Vector2(keyframe._values[i][6][0],keyframe._values[i][6][1]) if len(keyframe._values[i]) > 6 else Vector2.ZERO,
						Vector2(keyframe._values[i][5][0], keyframe._values[i][5][1])
					)
					
			var value := Quaternion.IDENTITY
			var tangent_out := Quaternion.IDENTITY
			var tangent_in := Quaternion.IDENTITY

			# Why can't a Quaternion be indexed?
			
			if(keyframe._values[0] != null):
				value.x = keyframe._values[0][2]
				tangent_out.x = keyframe._values[0][5][1]
				if(len(keyframe._values[0]) > 6): tangent_in.x = keyframe._values[0][6][1]
			if(keyframe._values[1] != null):
				value.y = keyframe._values[1][2]
				tangent_out.y = keyframe._values[1][5][1]
				if(len(keyframe._values[1]) > 6): tangent_in.y = keyframe._values[1][6][1]
			if(keyframe._values[2] != null):
				value.z = keyframe._values[2][3]
				tangent_out.z = keyframe._values[2][5][1]
				if(len(keyframe._values[2]) > 6): tangent_in.z = keyframe._values[2][6][1]
			if(keyframe._values[3] != null): 
				value.w = keyframe._values[3][4]
				tangent_out.w = keyframe._values[3][5][1]
				if(len(keyframe._values[3]) > 6): tangent_in.w = keyframe._values[3][6][1]

			if(transform_func):
				value = transform_func._callable.call(value)
				tangent_out = transform_func._callable.call(tangent_out)
				tangent_in = transform_func._callable.call(tangent_in)

			if(keyframe._values[0] != null && keyframe._values[0][0]):
				animation.bezier_track_insert_key(
					track_indices[0],
					keyframe._frame * animation.step - start_offset,
					value.x,
					Vector2(keyframe._values[0][6][0], tangent_in.x) if len(keyframe._values[0]) > 6 else Vector2.ZERO,
					Vector2(keyframe._values[0][5][0], tangent_out.x)
				)
			if(keyframe._values[1] != null && keyframe._values[1][0]):
				animation.bezier_track_insert_key(
					track_indices[1],
					keyframe._frame * animation.step - start_offset,
					value.y,
					Vector2(keyframe._values[1][6][0], tangent_in.y) if len(keyframe._values[1]) > 6 else Vector2.ZERO,
					Vector2(keyframe._values[1][5][0], tangent_out.y)
				)
			if(keyframe._values[2] != null && keyframe._values[2][0]):
				animation.bezier_track_insert_key(
					track_indices[2],
					keyframe._frame * animation.step - start_offset,
					value.z,
					Vector2(keyframe._values[2][6][0], tangent_in.z) if len(keyframe._values[2]) > 6 else Vector2.ZERO,
					Vector2(keyframe._values[2][5][0], tangent_out.z)
				)
			if(keyframe._values[3] != null && keyframe._values[3][0]):
				animation.bezier_track_insert_key(
					track_indices[3],
					keyframe._frame * animation.step - start_offset,
					value.w,
					Vector2(keyframe._values[3][6][0], tangent_in.w) if len(keyframe._values[3]) > 6 else Vector2.ZERO,
					Vector2(keyframe._values[3][5][0], tangent_out.w)
				)


static func import_scale_3d(context: STF_ImportContext, animation: Animation, target: String, track: Dictionary, start_offset: float, use_baked = false, simplify = false, transform_func: STF_Module.OptionalCallable = null):
	if(simplify):
		var track_index = animation.add_track(Animation.TYPE_SCALE_3D)
		animation.track_set_path(track_index, target)
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Vector3.ZERO
			for i in range(len(keyframe)):
				if(keyframe._values[i] != null):
					value[i] = keyframe._values[i][2]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe._frame * animation.step - start_offset, value, 1)
	elif(use_baked):
		var track_index = animation.add_track(Animation.TYPE_SCALE_3D)
		animation.track_set_path(track_index, target)
		var keyframe_index = start_offset
		for keyframe in STFAnimationImportUtil.arrange_baked_keyframes(context, track):
			var value := Vector3.ZERO
			for i in range(len(keyframe)):
				if(keyframe[i] != null):
					value[i] = keyframe[i]
			if(transform_func):
				value = transform_func._callable.call(value)
			animation.track_insert_key(track_index, keyframe_index * animation.step - start_offset, value, 1)
			keyframe_index += 1
	else:
		var track_indices := [animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER), animation.add_track(Animation.TYPE_BEZIER)]
		animation.track_set_path(track_indices[0], target + ":scale:x")
		animation.track_set_path(track_indices[1], target + ":scale:y")
		animation.track_set_path(track_indices[2], target + ":scale:z")
		for keyframe in STFAnimationImportUtil.arrange_unbaked_keyframes(track):
			var value := Vector3.ZERO
			var tangent_in := Vector3.ZERO
			var tangent_out := Vector3.ZERO
			for i in range(len(keyframe)):
				if(keyframe._values[i] != null && keyframe._values[i][0]):
					value[i] = keyframe._values[i][2]
					tangent_in[i] = keyframe._values[i][6][1] if len(keyframe._values[i]) > 6 else 0
					tangent_out[i] = keyframe._values[i][5][1]
			if(transform_func):
				value = transform_func._callable.call(value)
				tangent_in = transform_func._callable.call(tangent_in)
				tangent_out = transform_func._callable.call(tangent_out)
			for i in range(len(keyframe)):
				if(keyframe._values[i] != null && keyframe._values[i][0]):
					animation.bezier_track_insert_key(
						track_indices[i],
						keyframe._frame * animation.step - start_offset,
						value[i],
						Vector2(keyframe._values[i][6][0], tangent_in[i]) if len(keyframe._values[i]) > 6 else Vector2.ZERO,
						Vector2(keyframe._values[i][5][0], tangent_out[i])
					)

