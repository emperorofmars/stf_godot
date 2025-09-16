class_name OptionalCallable
extends RefCounted

var _callable: Callable

func _init(callable: Callable) -> void:
	self._callable = callable

func call(...args):
	self._callable.call(args)
