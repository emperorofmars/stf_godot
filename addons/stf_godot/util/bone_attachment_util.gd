class_name BoneAttachmentUtil

static func ensure_attachment(skeleton: Skeleton3D, bone_index: int) -> Node3D:
	for child in skeleton.get_children():
		if(child is BoneAttachment3D && child.bone_idx == bone_index):
			return child

	var bone_attachment = BoneAttachment3D.new()
	bone_attachment.name = "Attachment " + skeleton.get_bone_name(bone_index)
	skeleton.add_child(bone_attachment)
	bone_attachment.bone_idx = bone_index
	return bone_attachment
