class_name STF_AnimationPropertyResult
extends RefCounted

var _godot_path: String
var _track_type: int
var _keyframe_converter: Callable

func _init(godot_path: String, track_type: int, keyframe_converter: Callable = func (v): return v) -> void:
	self._godot_path = godot_path
	self._track_type = track_type
	self._keyframe_converter = keyframe_converter
