class_name STF_Instance_Mesh
extends STF_Module

func _get_stf_type() -> String:
	return "stf.instance.mesh"

func _get_priority() -> int:
	return 0

func _get_stf_kind() -> String:
	return "instance"

func _get_like_types() -> Array[String]:
	return ["instance.mesh", "instance"]

func _get_godot_type() -> String:
	return "MeshInstance3D"

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> Variant:
	var ret = MeshInstance3D.new()
	ret.name = json_resource.get("name", "STF Instance Mesh")

	ret.set_meta("stf_id", stf_id)
	ret.set_meta("stf_name", json_resource.get("name", null))

	#if("armature_instance" in json_resource):
		#ret.skeleton = context.import(json_resource["armature_instance"])

	ret.mesh = context.import(json_resource["mesh"])

	return ret

func _export() -> STF_ResourceExport:
	return null

