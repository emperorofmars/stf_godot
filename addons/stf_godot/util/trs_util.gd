class_name STF_TRS_Util

static func parse_vec3(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])

static func parse_quat(values: Array) -> Quaternion:
	return Quaternion(values[0], values[1], values[2], values[3])

static func parse_transform(values: Array) -> Transform3D:
	return Transform3D(Basis(parse_quat(values[1])).scaled(parse_vec3(values[2])), parse_vec3(values[0]))


static func serialize_vec3(value: Vector3) -> Array[float]:
	return [value[0], value[1], value[2]]

static func serialize_quat(value: Quaternion) -> Array[float]:
	return [value.x, value.y, value.z, value.w]

static func serialize_transform(value: Transform3D) -> Array[Array]:
	return [
		serialize_vec3(value.origin),
		serialize_quat(value.basis.get_rotation_quaternion()),
		serialize_vec3(value.basis.get_scale())
	]
