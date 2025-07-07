class_name STF_Prefab
extends STF_Module

func get_stf_type() -> String:
	return "stf.prefab"

func get_priority() -> int:
	return 0

func get_stf_kind() -> String:
	return "data"

func get_like_types() -> Array[String]:
	return ["prefab"]

func get_godot_type() -> String:
	return "Node3D"

func import() -> Object:
	return null

func export() -> Object:
	return null
