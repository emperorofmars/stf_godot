class_name STF_Info
extends Resource
## Represents the meta information of an STF file

@export
var root: String
@export
var definition_version_major: int = 0
@export
var definition_version_minor: int = 1

@export
var generator: String = "stf_godot"
@export
var generator_version: String = "0.0.1"
@export
var timestamp: String
@export
var metric_multiplier: float =  1

@export
var asset_name: String
@export
var asset_version: String
@export
var asset_url: String
@export
var asset_author: String
@export
var asset_license: String
@export
var asset_license_url: String
@export
var asset_documentation_url: String

@export
var asset_properties: Dictionary = {}

static func parse(json_definition: Dictionary) -> STF_Info:
	if("stf" not in json_definition): return null
	var stf = json_definition["stf"]
	if("root" not in stf): return null

	var ret = STF_Info.new()
	ret.resource_name = "stf_meta"
	ret.root = stf["root"]
	ret.definition_version_major = stf.get("version", [0, 1])[0]
	ret.definition_version_minor = stf.get("version", [0, 1])[1]
	ret.generator = stf.get("generator")
	ret.generator_version = stf.get("generator_version")
	ret.timestamp = stf.get("timestamp")
	ret.metric_multiplier = stf.get("metric_multiplier")

	if("asset_info" in stf):
		var asset_info: Dictionary = stf["asset_info"]
		ret.asset_name = asset_info.get("asset_name", "")
		ret.asset_version = asset_info.get("version", "")
		ret.asset_url = asset_info.get("url", "")
		ret.asset_author = asset_info.get("author", "")
		ret.asset_license = asset_info.get("license", "")
		ret.asset_license_url = asset_info.get("license_url", "")
		ret.asset_documentation_url = asset_info.get("documentation_url", "")

	if("asset_properties" in stf):
		ret.asset_properties = stf["asset_properties"]

	return ret


static func serialize_asset_info(stf_info: STF_Info) -> Dictionary:
	var ret = {}
	if(stf_info.asset_name): ret["asset_name"] = stf_info.asset_name
	if(stf_info.asset_version): ret["version"] = stf_info.asset_version
	if(stf_info.asset_url): ret["url"] = stf_info.asset_url
	if(stf_info.asset_author): ret["author"] = stf_info.asset_author
	if(stf_info.asset_license): ret["license"] = stf_info.asset_license
	if(stf_info.asset_license): ret["license_url"] = stf_info.asset_license
	if(stf_info.asset_documentation_url): ret["documentation_url"] = stf_info.asset_documentation_url
	return ret

