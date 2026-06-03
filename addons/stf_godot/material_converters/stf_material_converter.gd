@abstract class_name STF_Material_Converter
extends RefCounted
## Converts an [code]stf.material[/code] resource into a Godot material.

## Name of the Godot material class
@abstract func _get_material_name() -> String

## If multiple material converters are registered for the same `material`, then the priority determines the match.
@abstract func _get_priority() -> int

## The main star for import.
@abstract func _convert(context: STF_ImportContext, stf_id: String, json_resource: Dictionary, context_object: Variant, instance_context: Variant) -> STF_Handler.ImportResult


func _set_stf_meta(stf_resource: STF_Resource, godot_object: Object) -> STF_Resource:
	godot_object.set_meta("stf_id", stf_resource._meta["stf_id"])
	godot_object.set_meta("stf", stf_resource._meta)
	return stf_resource


func _get_texture(stf_resource: STF_Resource, image: Image) -> Texture2D:
	if(not image): return null
	stf_resource.register_referenced_resource(image.get_meta("stf_id"), image)
	if("processed" in image.get_meta("stf") && len(image.get_meta("stf")["processed"]) > 0):
		return image.get_meta("stf")["processed"][0]
	else:
		return ImageTexture.create_from_image(image)
