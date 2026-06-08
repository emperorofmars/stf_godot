class_name STF_Bone_Model
extends Resource

@export
var children: Array[STF_Bone_Model] = []

@export
var translation: Vector3 = Vector3.ZERO
@export
var rotation: Quaternion = Quaternion.IDENTITY

@export
var length: float = 0

@export
var connected: bool = false

@export
var deform: bool = true

@export
var non_deform_use: String

@export
var _bone_index: int = -1
