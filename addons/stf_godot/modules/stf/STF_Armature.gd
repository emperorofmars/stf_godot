class_name STF_Armature
extends STF_Module

func _get_stf_type() -> String: return "stf.armature"
func _get_priority() -> int: return 0
func _get_stf_kind() -> String: return "data"
func _get_like_types() -> Array[String]: return ["armature"]
func _get_godot_type() -> String: return "Skeleton3D"

func _check_godot_object(godot_object: Object) -> int:
	return 1 if godot_object is Skeleton3D else -1 # todo this is wrong, devise a way to check for armatures vs armature instances

class ArmatureImportContext:
	extends RefCounted
	var _skeleton: Skeleton3D
	var _tasks: Array[Callable] = []
	func _init(skeleton: Skeleton3D):
		self._skeleton = skeleton
	func _add_task(task: Callable):
		self._tasks.append(task)
	func _run_tasks():
		const max_depth: = 1000
		var iter: = 0
		while(len(_tasks) > 0 && iter < max_depth):
			var tmp = _tasks
			_tasks = []
			for task in tmp:
				task.call()
			iter += 1

func _import(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant) -> ImportResult:
	var ret = Skeleton3D.new()
	ret.name = STF_Godot_Util.get_name_or_default(json_resource, "STF Armature")
	STF_Godot_Util.set_stf_meta(stf_id, json_resource, ret)
	
	var child_context = ArmatureImportContext.new(ret)

	for child_id in json_resource.get("root_bones", []):
		context.import(child_id, "node", child_context)

	ret.reset_bone_poses()
	
	child_context._run_tasks()

	return ImportResult.new(ret)

func _export(context: STF_ExportContext, godot_object: Variant, context_object: Variant) -> ExportResult:
	return null

