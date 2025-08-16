class_name STFAnimationImportUtil


static func arrange_unbaked_keyframes(track: Dictionary) -> Array[Array]:
	var subtracks = track.get("subtracks", [])
	var len = -1;
	for subtrack in subtracks:
		if(subtrack && len(subtrack["keyframes"]) > len):
			len = len(subtrack["keyframes"])
	if(len <= 0): return []

	var keyframes: Array[Array] = []
	for i in range(len):
		var value: Array[Dictionary] = []
		for subtrack_index in range(len(subtracks)):
			if(subtracks[subtrack_index] && subtracks[subtrack_index]["keyframes"][i]):
				value[subtrack_index] = subtracks[subtrack_index]["keyframes"][i]
		keyframes.append(value)
	
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
	if(len <= 0): return []

	var keyframes: Array[Array] = []
	for i in range(len):
		var subkeyframe = []
		for buffer in buffers:
			subkeyframe.append(buffer[i])
		keyframes.append(subkeyframe)
	
	return keyframes

