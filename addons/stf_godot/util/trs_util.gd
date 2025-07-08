class_name STF_TRS_Util

static func parse_vec3(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])

static func parse_quat(values: Array) -> Quaternion:
	return Quaternion(values[0], values[1], values[2], values[4])

static func parse_transform(values: Array) -> Transform3D:
	return Transform3D(Basis(parse_quat(values[1])).scaled(parse_vec3(values[2])), parse_vec3(values[0]))
