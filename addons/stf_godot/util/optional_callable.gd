class_name OptionalCallable
extends RefCounted
## Wrapper for [Callable] that can be [code]null[/code].

var _callable: Callable

func _init(callable: Callable) -> void:
	self._callable = callable

func call(...args) -> Variant:
	return self._callable.call(args)
