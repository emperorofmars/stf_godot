class_name STF_ImportContext
extends RefCounted
## Is passed to each STF module on import


var _state: STF_ImportState


func _init(state: STF_ImportState) -> void:
	_state = state


func import(stf_id: String) -> Variant:
	return null
