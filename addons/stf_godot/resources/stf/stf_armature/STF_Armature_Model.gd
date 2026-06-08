class_name STF_Armature_Model
extends Resource

@export
var root_bones: Array[STF_Bone_Model] = []

@export
var bones: Array[STF_Bone_Model] = []


func get_bone_count() -> int:
	return len(bones)

func get_bone_meta(bone_index: int, meta_key: String) -> Variant:
	return bones[bone_index].get_meta(meta_key)

