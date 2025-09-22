class_name STF_Mesh
extends STF_Module


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

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is Mesh else -1


func import_uint_buffer(buffer: PackedByteArray, width: int) -> Array:
	var ret = []
	for i in range(0, len(buffer) / width):
		match width:
			1: ret.append(buffer.decode_u8(i * width))
			2: ret.append(buffer.decode_u16(i * width))
			4: ret.append(buffer.decode_u32(i * width))
			8: ret.append(buffer.decode_u64(i * width))
	return ret


func import_vec4_buffer(buffer: PackedByteArray, width: int) -> PackedVector4Array:
	var tmp = null
	match width:
		4: tmp = buffer.to_float32_array()
		8: tmp = buffer.to_float64_array()
	var ret = PackedVector4Array()
	ret.resize(len(tmp) / 4)
	for i in range(len(tmp) / 4):
		ret[i] = Vector4(tmp[i * 4], tmp[i * 4 + 1], tmp[i * 4 + 2], tmp[i * 4 + 3])
	return ret


func import_vec3_buffer(buffer: PackedByteArray, width: int) -> PackedVector3Array:
	var tmp = null
	match width:
		4: tmp = buffer.to_float32_array()
		8: tmp = buffer.to_float64_array()
	var ret = PackedVector3Array()
	ret.resize(len(tmp) / 3)
	for i in range(len(tmp) / 3):
		ret[i] = Vector3(tmp[i * 3], tmp[i * 3 + 1], tmp[i * 3 + 2])
	return ret


func import_vec2_buffer(buffer: PackedByteArray, width: int) -> PackedVector2Array:
	var tmp = null
	match width:
		4: tmp = buffer.to_float32_array()
		8: tmp = buffer.to_float64_array()
	var ret = PackedVector2Array()
	ret.resize(len(tmp) / 2)
	for i in range(len(tmp) / 2):
		ret[i] = Vector2(tmp[i * 2], tmp[i * 2 + 1])
	return ret


func import_color_buffer(buffer: PackedByteArray, width: int) -> PackedColorArray:
	var tmp = null
	match width:
		4: tmp = buffer.to_float32_array()
		8: tmp = buffer.to_float64_array()
	var ret = PackedColorArray()
	ret.resize(len(tmp) / 4)
	for i in range(len(tmp) / 4):
		ret[i] = Color(tmp[i * 4], tmp[i * 4 + 1], tmp[i * 4 + 2], tmp[i * 4 + 3])
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


func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var BONES_PER_VERTEX: int = 4
	match context._get_import_options().get("max_weights", 0):
		0: BONES_PER_VERTEX = 4
		1: BONES_PER_VERTEX = 8

	var float_width: int = json_resource.get("float_width", 4)
	var indices_width: int = json_resource.get("indices_width", 4)
	var material_indices_width: int = json_resource.get("material_indices_width", 1)

	var vertices := import_vec3_buffer(context.get_buffer(json_resource["vertices"]), float_width)

	var split_indices := import_uint_buffer(context.get_buffer(json_resource["splits"]), indices_width)

	var face_corners := import_uint_buffer(context.get_buffer(json_resource["face_corners"]), indices_width) if "face_corners" in json_resource else range(len(split_indices))

	var normals := import_vec3_buffer(context.get_buffer(json_resource["split_normals"]), float_width) if "split_normals" in json_resource else PackedVector3Array()

	var colors := import_color_buffer(context.get_buffer(json_resource["split_colors"]), float_width) if "split_colors" in json_resource else PackedColorArray()

	var uv_channels = []
	var buffers_uv: Array[PackedVector2Array] = []
	if("uvs" in json_resource):
		for uv_channel_index in range(min(len(json_resource["uvs"]), 2)):
			var uv_channel = json_resource["uvs"][uv_channel_index]
			uv_channels.append(uv_channel.get("name", "UV"))
			var uv := import_vec2_buffer(context.get_buffer(uv_channel["uv"]), float_width)
			buffers_uv.append(uv)


	# optimization
	var compareUVs = func(a: int, b: int) -> bool:
		for uv in buffers_uv:
			if ((uv[a] - uv[b]).length() > 0.0001):
				return false
		return true

	var compareColors = func(a: int, b: int) -> bool:
		for i in range(4):
			if (abs(colors[a][i] - colors[b][i]) > 0.0001):
				return false
		return true

	var verts_to_split: Dictionary[int, Array] = {}
	var deduped_split_indices: Array[int] = []
	var split_to_deduped_split_index: Array[int] = []
	for split_index in range(len(split_indices)):
		var vertex_index = split_indices[split_index]

		if (vertex_index not in verts_to_split):
			verts_to_split[vertex_index] = [split_index]
			deduped_split_indices.append(split_index)
			split_to_deduped_split_index.append(len(deduped_split_indices) - 1)
		else:
			var success = false
			for candidate_index in range(len(verts_to_split[vertex_index])):
				var split_candidate = verts_to_split[vertex_index][candidate_index]
				if (
					(len(normals) != len(split_indices) || (normals[split_index] - normals[split_candidate]).length() < 0.0001)
					&& compareUVs.call(split_index, split_candidate)
					&& (len(colors) != len(split_indices) || compareColors.call(split_index, split_candidate))
				):
					split_to_deduped_split_index.append(split_to_deduped_split_index[split_candidate])
					success = true
					break
			if (!success):
				verts_to_split[vertex_index].append(split_index)
				deduped_split_indices.append(split_index)
				split_to_deduped_split_index.append(len(deduped_split_indices) - 1)

	var godot_vertices := PackedVector3Array()
	godot_vertices.resize(len(deduped_split_indices))

	var godot_normals := PackedVector3Array()
	if(len(normals) == len(split_indices)):
		godot_normals.resize(len(deduped_split_indices))

	var godot_colors := PackedColorArray()
	if(len(colors) == len(split_indices)):
		godot_colors.resize(len(deduped_split_indices))

	var godot_uvs: Array[PackedVector2Array] = []
	for uv_index in range(len(buffers_uv)):
		var uv = PackedVector2Array()
		uv.resize(len(deduped_split_indices))
		godot_uvs.append(uv);

	for i in range(len(deduped_split_indices)):
		godot_vertices[i] = vertices[split_indices[deduped_split_indices[i]]]
		if(len(normals) == len(split_indices)):
			godot_normals[i] = normals[deduped_split_indices[i]].normalized()
		if(len(colors) == len(split_indices)):
			godot_colors[i] = colors[deduped_split_indices[i]]
		for uv_index in range(len(buffers_uv)):
			godot_uvs[uv_index][i] = buffers_uv[uv_index][deduped_split_indices[i]]


	# topology
	var tris = import_uint_buffer(context.get_buffer(json_resource["tris"]), indices_width)
	if("face_corners" in json_resource):
		var tmp = tris
		tris = []
		for t in tmp:
			tris.append(face_corners[t])
	var face_lengths = import_uint_buffer(context.get_buffer(json_resource["faces"]), indices_width)
	var face_material_indices = import_uint_buffer(context.get_buffer(json_resource["material_indices"]), material_indices_width)


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
		var weight_lens_width: int = json_resource.get("weight_lens_width", 1)

		var buffer_weight_lens = import_uint_buffer(context.get_buffer(json_resource["weight_lens"]), weight_lens_width)
		var buffer_bone_indices = import_uint_buffer(context.get_buffer(json_resource["bone_indices"]), bone_indices_width)
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

			var weight_len = buffer_weight_lens[vertex_index]
			for weight_index in range(weight_len):
				var bone_index = buffer_bone_indices[position]
				var bone_weight = get_float_from_buffer(buffer_weights, position * float_width, float_width)
				position += 1

				vertex_bones.append(stf_to_godot_bone_index[bone_index])
				vertex_weights.append(bone_weight)

			vertex_bones.sort_custom(func (a, b): vertex_weights[vertex_bones.find(a)] > vertex_weights[vertex_bones.find(b)])
			vertex_weights.sort_custom(func (a, b): a > b)

			var weights_sum = 0
			for i in range(min(weight_len, BONES_PER_VERTEX)):
				weights_sum += vertex_weights[i]
			if(weights_sum == 0): weights_sum = 1

			for i in range(min(weight_len, BONES_PER_VERTEX)):
				bones.append(vertex_bones[i])
				weights.append(vertex_weights[i] / weights_sum)
			for i in range(BONES_PER_VERTEX - min(weight_len, BONES_PER_VERTEX)):
				bones.append(0)
				weights.append(0)

		for i in range(len(deduped_split_indices)):
			var vertex_index = split_indices[deduped_split_indices[i]]
			for j in range(BONES_PER_VERTEX):
				if(bones[vertex_index * BONES_PER_VERTEX + j] >= 0):
					godot_bones.append(bones[vertex_index * BONES_PER_VERTEX + j])
					godot_weights.append(weights[vertex_index * BONES_PER_VERTEX + j])
				else:
					godot_bones.append(0)
					godot_weights.append(0)


	# blendshapes
	var blendshapes: Array[Array] = []
	var blendshape_values: Array[float] = []
	var blendshape_names: Array[String] = []
	if("blendshapes" in json_resource):
		var blendshape_index = 0
		for json_blendshape in json_resource["blendshapes"]:
			var indexed = "indices" in json_blendshape
			var blendshape_indices := PackedInt32Array(import_uint_buffer(context.get_buffer(json_blendshape["indices"]), indices_width)) if indexed else PackedInt32Array(range(len(vertices)))

			var blendshape_vertices := import_vec3_buffer(context.get_buffer(json_blendshape["position_offsets"]), float_width)

			var godot_blendshape_vertices = PackedVector3Array()
			godot_blendshape_vertices.resize(len(godot_vertices))

			for blendshape_vertex_index in range(len(blendshape_indices)):
				var vertex_index = blendshape_indices[blendshape_vertex_index]
				for split_index in verts_to_split[vertex_index]:
					godot_blendshape_vertices[split_to_deduped_split_index[split_index]] = blendshape_vertices[blendshape_vertex_index]

			var godot_blendshape_normals = godot_normals.duplicate()

			if(len(godot_normals) == len(godot_vertices) && "split_normals" in json_blendshape):
				var blendshape_split_indices := PackedInt32Array(import_uint_buffer(context.get_buffer(json_blendshape["split_indices"]), indices_width)) if indexed else PackedInt32Array(range(len(normals)))
				var blendshape_normals := import_vec3_buffer(context.get_buffer(json_blendshape["split_normals"]), float_width)
				for blendshape_split_index in range(len(blendshape_split_indices)):
					var split_index = blendshape_split_indices[blendshape_split_index]
					godot_blendshape_normals[split_to_deduped_split_index[split_index]] = blendshape_normals[blendshape_split_index]

			var blendshape_arrays = []
			blendshape_arrays.resize(Mesh.ARRAY_MAX)
			blendshape_arrays[Mesh.ARRAY_VERTEX] = godot_blendshape_vertices
			if(len(godot_normals) == len(godot_vertices)): blendshape_arrays[Mesh.ARRAY_NORMAL] = godot_blendshape_normals

			blendshapes.append(blendshape_arrays)
			blendshape_names.append(json_blendshape["name"] if "name" in json_blendshape else ("Blendshape " + str(blendshape_index)))

			if("default_value" in json_blendshape):
				blendshape_values.append(json_blendshape["default_value"])
			else:
				blendshape_values.append(0.0)


	#var ret = ImporterMesh.new()
	var ret = ArrayMesh.new()
	ret.resource_name = STF_Godot_Util.get_name_or_default(json_resource, "STF Mesh")

	ret.set_meta("stf_id", stf_id)
	var stf_meta := {"stf_name": json_resource.get("name"), "blendshape_values": blendshape_values}
	ret.set_meta("stf", stf_meta)

	ret.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	#ret.set_blend_shape_mode(Mesh.BLEND_SHAPE_MODE_NORMALIZED)

	for name in blendshape_names:
		ret.add_blend_shape(name)

	for sub_mesh in sub_mesh_indices:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)

		# map indices from whole mesh to submesh
		var submesh_map: Dictionary[int, int] = {}
		var pos = 0
		for submesh_index in sub_mesh:
			if(submesh_index not in submesh_map):
				submesh_map[submesh_index] = pos
				pos += 1

		# triangle indices
		var submesh_indices = PackedInt32Array()
		submesh_indices.resize(len(sub_mesh))
		pos = 0
		for submesh_index in sub_mesh:
			submesh_indices[pos] = submesh_map[submesh_index]
			pos += 1
		arrays[Mesh.ARRAY_INDEX] = submesh_indices

		# vertices
		var submesh_vertices = PackedVector3Array()
		submesh_vertices.resize(len(submesh_map))
		for submesh_index in submesh_map:
			submesh_vertices[submesh_map[submesh_index]] = godot_vertices[submesh_index]
		arrays[Mesh.ARRAY_VERTEX] = submesh_vertices

		# normals
		if(len(godot_normals) == len(godot_vertices)):
			var submesh_normals = PackedVector3Array()
			submesh_normals.resize(len(submesh_map))
			for submesh_index in submesh_map:
				submesh_normals[submesh_map[submesh_index]] = godot_normals[submesh_index]
			arrays[Mesh.ARRAY_NORMAL] = submesh_normals

		# uv maps
		if(len(godot_uvs) > 0):
			var submesh_uv = PackedVector2Array()
			submesh_uv.resize(len(submesh_map))
			for submesh_index in submesh_map:
				submesh_uv[submesh_map[submesh_index]] = godot_uvs[0][submesh_index]
			arrays[Mesh.ARRAY_TEX_UV] = submesh_uv
		if(len(godot_uvs) > 1):
			var submesh_uv = PackedVector2Array()
			submesh_uv.resize(len(submesh_map))
			for submesh_index in submesh_map:
				submesh_uv[submesh_map[submesh_index]] = godot_uvs[1][submesh_index]
			arrays[Mesh.ARRAY_TEX_UV2] = submesh_uv

		# colors
		if(len(godot_colors) == len(godot_vertices)):
			var submesh_colors = PackedColorArray()
			submesh_colors.resize(len(submesh_map))
			for submesh_index in submesh_map:
				submesh_colors[submesh_map[submesh_index]] = godot_colors[submesh_index]
			arrays[Mesh.ARRAY_COLOR] = submesh_colors


		# weightpaint
		if(len(godot_bones) == len(godot_vertices) * BONES_PER_VERTEX && len(godot_weights) == len(godot_vertices) * BONES_PER_VERTEX):
			var submesh_bones = PackedInt32Array()
			var submesh_weights = PackedFloat32Array()
			submesh_bones.resize(len(submesh_map) * BONES_PER_VERTEX)
			submesh_weights.resize(len(submesh_map) * BONES_PER_VERTEX)
			for submesh_index in submesh_map:
				for i in range(BONES_PER_VERTEX):
					submesh_bones[submesh_map[submesh_index] * BONES_PER_VERTEX + i] = godot_bones[submesh_index * BONES_PER_VERTEX + i]
					submesh_weights[submesh_map[submesh_index] * BONES_PER_VERTEX + i] = godot_weights[submesh_index * BONES_PER_VERTEX + i]
			arrays[Mesh.ARRAY_BONES] = submesh_bones
			arrays[Mesh.ARRAY_WEIGHTS] = submesh_weights

		# blendshapes
		var submesh_blendshapes: Array[Array] = []
		for blendshape in blendshapes:
			var submesh_blendshape = []
			submesh_blendshape.resize(Mesh.ARRAY_MAX)

			var submesh_blendshape_vertices = PackedVector3Array()
			submesh_blendshape_vertices.resize(len(submesh_map))
			for submesh_index in submesh_map:
				submesh_blendshape_vertices[submesh_map[submesh_index]] = blendshape[Mesh.ARRAY_VERTEX][submesh_index] + godot_vertices[submesh_index]
			submesh_blendshape[Mesh.ARRAY_VERTEX] = submesh_blendshape_vertices

			if(len(normals) == len(godot_vertices)):
				var submesh_blendshape_normals = PackedVector3Array()
				submesh_blendshape_normals.resize(len(submesh_map))
				for submesh_index in submesh_map:
					submesh_blendshape_normals[submesh_map[submesh_index]] = blendshape[Mesh.ARRAY_NORMAL][submesh_index]
				submesh_blendshape[Mesh.ARRAY_NORMAL] = submesh_blendshape_normals

			submesh_blendshapes.append(submesh_blendshape)


		var flags = 0
		if(BONES_PER_VERTEX == 8):
			flags |= Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS

		#ret.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, submesh_blendshapes, {}, null, "", flags)
		ret.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, submesh_blendshapes, {}, flags)

	if("material_slots" in json_resource):
		for material_index in range(len(json_resource["material_slots"])):
			var material_id = json_resource["material_slots"][material_index]
			if(material_id):
				var material = context.import(material_id, "data")
				if(material):
					ret.surface_set_material(material_index, material)
					#ret.set_surface_material(material_index, material)

	#ret.generate_lods(60, 60, [])

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

