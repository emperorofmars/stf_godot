class_name STF_AnimationPropertyResolver
extends RefCounted


func resolve(stf_path: Array, godot_object: Object) -> STF_AnimationPropertyResult:
	return STF_AnimationPropertyResult.new("foo", Animation.TYPE_BEZIER)
