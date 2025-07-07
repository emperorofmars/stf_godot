class_name STF_File
extends RefCounted
## Deconstructed representation of an STF file
## Provides convenient access to get or add buffers


var binary_version_major: int = 0
var binary_version_minor: int = 0

var json_definition: Dictionary = {}
var buffers: Array[PackedByteArray] = []


static func read(path: String) -> STF_File:
	var ret = STF_File.new()
	var file = FileAccess.open(path, FileAccess.READ)
	
	if(file.get_buffer(4).get_string_from_ascii() != "STF0"):
		printerr("Error importing STF file: Invalid magic number")
		return null
	
	ret.binary_version_major = file.get_32()
	ret.binary_version_minor = file.get_32()
	
	var num_buffers = file.get_32()
	if(num_buffers < 1):
		printerr("Error importing STF file: At least one buffer is required")
		return null
	
	var buffer_lens = []
	for i in range(num_buffers):
		buffer_lens.append(file.get_64())
	
	ret.json_definition = JSON.parse_string(file.get_buffer(buffer_lens[0]).get_string_from_utf8())
	if(!ret.json_definition):
		printerr("Error importing STF file: Invalid Json definition")
		return null

	for i in range(1, num_buffers):
		ret.buffers.append(file.get_buffer(buffer_lens[i]))
	
	return ret


func write(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer("STF0".to_ascii_buffer())
	file.store_32(binary_version_major)
	file.store_32(binary_version_minor)
	file.store_32(len(buffers) + 1)
	var json_definition_buffer =  JSON.stringify(json_definition).to_utf8_buffer()
	file.store_64(len(json_definition_buffer))
	for buffer in buffers:
		file.store_64(len(buffer))
	file.store_buffer(json_definition_buffer)
	for buffer in buffers:
		file.store_buffer(buffer)


func add_buffer(buffer: PackedByteArray) -> int:
	buffers.append(buffer)
	return len(buffers) - 1

func get_buffer(index: int) -> PackedByteArray:
	return buffers[index]
