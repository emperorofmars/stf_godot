class_name STF_Mesh
extends STF_Module


const MAX_BONES_PER_VERTEX: int = 4


func _get_stf_type() -> String:
	return "stf.mesh"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "data"

func _get_like_types() -> Array[String]:
	return ["mesh"]

func _get_godot_type() -> String:
	return "Mesh"


func get_uint_buffer(buffer: PackedByteArray, width: int) -> Array:
	var ret = []
	for i in range(0, len(buffer) / width):
		match width:
			1: ret.append(buffer.decode_u8(i * width))
			2: ret.append(buffer.decode_u16(i * width))
			4: ret.append(buffer.decode_u32(i * width))
			8: ret.append(buffer.decode_u64(i * width))
	return ret


func get_int_from_buffer(buffer: PackedByteArray, offset_bytes: int, width: int) -> int:
	match width:
		1: return buffer.decode_s8(offset_bytes)
		2: return buffer.decode_s16(offset_bytes)
		4: return buffer.decode_s32(offset_bytes)
		8: return buffer.decode_s64(offset_bytes)
		_: return -1


func get_uint_from_buffer(buffer: PackedByteArray, offset_bytes: int, width: int) -> int:
	match width:
		1: return buffer.decode_u8(offset_bytes)
		2: return buffer.decode_u16(offset_bytes)
		4: return buffer.decode_u32(offset_bytes)
		8: return buffer.decode_u64(offset_bytes)
		_: return -1


func get_float_from_buffer(buffer: PackedByteArray, offset_bytes: int, width: int) -> float:
	match width:
		2: return buffer.decode_half(offset_bytes)
		4: return buffer.decode_float(offset_bytes)
		8: return buffer.decode_double(offset_bytes)
		_: return NAN


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var ret = ArrayMesh.new()
	ret.resource_name = json_resource.get("name", "STF Mesh")

	ret.set_meta("stf_id", stf_id)
	ret.set_meta("stf_name", json_resource.get("name", null))

	
	var float_width: int = json_resource.get("float_width", 4)
	var indices_width: int = json_resource.get("indices_width", 4)
	var material_indices_width: int = json_resource.get("material_indices_width", 1)

	var buffer_vertices = null
	match float_width:
		4: buffer_vertices = context.get_buffer(json_resource["vertices"]).to_float32_array()
		8: buffer_vertices = context.get_buffer(json_resource["vertices"]).to_float64_array()
	var vertices = PackedVector3Array()
	for i in range(len(buffer_vertices) / 3):
		vertices.push_back(Vector3(buffer_vertices[i * 3], buffer_vertices[i * 3 + 1], buffer_vertices[i * 3 + 2]))
	
	var split_indices = get_uint_buffer(context.get_buffer(json_resource["splits"]), indices_width)
	
	var buffer_split_normals = null
	match float_width:
		4: buffer_split_normals = context.get_buffer(json_resource["split_normals"]).to_float32_array()
		8: buffer_split_normals = context.get_buffer(json_resource["split_normals"]).to_float64_array()
	var normals := PackedVector3Array()
	for i in range(len(buffer_split_normals) / 3):
		normals.push_back(Vector3(buffer_split_normals[i * 3], buffer_split_normals[i * 3 + 1], buffer_split_normals[i * 3 + 2]))
	
	var uv_channels = []
	var buffers_uv: Array[PackedVector2Array] = []
	if("uvs" in json_resource):
		for uv_channel in json_resource["uvs"]:
			uv_channels.append(uv_channel.get("name", "UV"))
			var buffer_uv = null
			match float_width:
				4: buffer_uv = context.get_buffer(uv_channel["uv"]).to_float32_array()
				8: buffer_uv = context.get_buffer(uv_channel["uv"]).to_float64_array()
				_: break
			var uv := PackedVector2Array()
			for i in range(len(buffer_uv) / 2):
				uv.push_back(Vector2(buffer_uv[i * 2], buffer_uv[i * 2 + 1]))
			buffers_uv.append(uv)

	var buffers_split_colors = [] # todo


	var compareUVs = func(a: int, b: int) -> bool:
		for uv in buffers_uv:
			if ((uv[a] - uv[b]).length() > 0.0001):
				return false
		return true

	var verts_to_split: Dictionary[int, Array] = {}
	var deduped_split_indices: Array[int] = []
	var split_to_deduped_split_index: Array[int] = []
	for splitIndex in range(len(split_indices)):
		var vertexIndex = split_indices[splitIndex]

		if (vertexIndex not in verts_to_split):
			verts_to_split[vertexIndex] = [splitIndex]
			deduped_split_indices.append(splitIndex)
			split_to_deduped_split_index.append(len(deduped_split_indices) - 1)
		else:
			var success = false
			for candidateIndex in range(len(verts_to_split[vertexIndex])):
				var splitCandidate = verts_to_split[vertexIndex][candidateIndex]
				if (
					(normals[splitIndex] - normals[splitCandidate]).length() < 0.0001
					&& compareUVs.call(splitIndex, splitCandidate)
					# TODO colors
				):
					split_to_deduped_split_index.append(split_to_deduped_split_index[splitCandidate])
					success = true
					break
			if (!success):
				verts_to_split[vertexIndex].append(splitIndex)
				deduped_split_indices.append(splitIndex)
				split_to_deduped_split_index.append(len(deduped_split_indices) - 1)


	var godot_vertices := PackedVector3Array()
	var godot_normals := PackedVector3Array()
	var godot_uvs: Array[PackedVector2Array] = []

	for uv_index in range(len(buffers_uv)):
		godot_uvs.append(PackedVector2Array());

	for i in range(len(deduped_split_indices)):
		godot_vertices.append(vertices[split_indices[deduped_split_indices[i]]])
		godot_normals.append(normals[deduped_split_indices[i]])
		for uv_index in range(len(buffers_uv)):
			godot_uvs[uv_index].append(buffers_uv[uv_index][deduped_split_indices[i]])

	var tris = get_uint_buffer(context.get_buffer(json_resource["tris"]), indices_width)
	var face_lengths = get_uint_buffer(context.get_buffer(json_resource["faces"]), indices_width)
	var face_material_indices = get_uint_buffer(context.get_buffer(json_resource["material_indices"]), material_indices_width)


	var sub_mesh_indices: Array[PackedInt32Array] = []
	var tris_index = 0
	for face_index in range(len(face_lengths)):
		var mat_index: int = face_material_indices[face_index]
		for face_len in range(face_lengths[face_index]):
			while len(sub_mesh_indices) <= mat_index: sub_mesh_indices.append(PackedInt32Array())

			sub_mesh_indices[mat_index].append(split_to_deduped_split_index[tris[tris_index * 3 + 2]])
			sub_mesh_indices[mat_index].append(split_to_deduped_split_index[tris[tris_index * 3 + 1]])
			sub_mesh_indices[mat_index].append(split_to_deduped_split_index[tris[tris_index * 3]])

			tris_index += 1


	# weights
	var godot_bones := PackedInt32Array()
	var godot_weights := PackedFloat32Array()
	if("armature" in json_resource && "bones" in json_resource && "weights" in json_resource):
		var armature: Skeleton3D = context.import(json_resource["armature"])

		var bones_ids: Array = json_resource["bones"]
		var bone_indices_width: int = json_resource.get("bone_indices_width", 1)
		
		var buffer_weight_lens = get_uint_buffer(context.get_buffer(json_resource["weight_lens"]), indices_width)
		var buffer_weights = context.get_buffer(json_resource["weights"])

		var stf_to_godot_bone_index: Dictionary[int, int] = {}

		for stf_bone_index in range(len(bones_ids)):
			var bone_id = bones_ids[stf_bone_index]
			var godot_bone_index = -1
			for i in range(armature.get_bone_count()):
				if(armature.get_bone_meta(i, "stf_id") == bone_id):
					godot_bone_index = i
					break
			stf_to_godot_bone_index[stf_bone_index] = godot_bone_index

		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		var position = 0;
		for vertex_index in range(len(buffer_weight_lens)):
			var vertex_bones = []
			var vertex_weights = []
			var weights_sum = 0

			var weight_len = buffer_weight_lens[vertex_index]
			for weight_index in range(weight_len):
				var bone_index = get_uint_from_buffer(buffer_weights, position, bone_indices_width)
				position += bone_indices_width
				var bone_weight = get_float_from_buffer(buffer_weights, position, float_width)
				position += float_width

				vertex_bones.append(stf_to_godot_bone_index[bone_index])
				vertex_weights.append(bone_weight)
				weights_sum += bone_weight

			vertex_bones.sort_custom(func (a, b): vertex_weights[vertex_bones.find(a)] > vertex_weights[vertex_bones.find(b)])
			vertex_weights.sort_custom(func (a, b): a > b)
			
			if(weights_sum == 0): weights_sum = 1

			for i in range(min(weight_len, 4)):
				bones.append(vertex_bones[i])
				weights.append(vertex_weights[i] / weights_sum)
			for i in range(4 - min(weight_len, 4)):
				bones.append(0)
				weights.append(0)

		for i in range(len(deduped_split_indices)):
			var vertex_index = split_indices[deduped_split_indices[i]]
			for j in range(4):
				if(bones[vertex_index * 4 + j] >= 0):
					godot_bones.append(bones[vertex_index * 4 + j])
					godot_weights.append(weights[vertex_index * 4 + j])
				else:
					godot_bones.append(0)
					godot_weights.append(0)
	
	# todo blendshapes


	for sub_mesh in sub_mesh_indices:
		# todo optimize submesh
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_INDEX] = sub_mesh
		arrays[Mesh.ARRAY_VERTEX] = godot_vertices
		if(len(godot_normals) == len(godot_vertices)):
			arrays[Mesh.ARRAY_NORMAL] = godot_normals
		if(len(godot_uvs) > 0):
			arrays[Mesh.ARRAY_TEX_UV] = godot_uvs[0]
		if(len(godot_uvs) > 1):
			arrays[Mesh.ARRAY_TEX_UV2] = godot_uvs[1]

		if(len(godot_bones) == len(godot_vertices) * 4 && len(godot_weights) == len(godot_vertices) * 4):
			arrays[Mesh.ARRAY_BONES] = godot_bones
			arrays[Mesh.ARRAY_WEIGHTS] = godot_weights

		ret.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		#ret.surface_set_name(0, "")

	return ret

func _export() -> STF_ResourceExport:
	return null

