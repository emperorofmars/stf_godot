class_name STF_Info
extends RefCounted
## Represents the meta information of an STF file

var root: String
var definition_version_major: int = 0
var definition_version_minor: int = 0

var generator: String = "stf_godot"
var generator_version: String = "0.0.1"
var timestamp: String
var metric_multiplier: float =  1

var asset_name: String
var asset_version: String
var asset_url: String
var asset_author: String
var asset_license: String
var asset_license_url: String
var asset_documentation_url: String

var user_properties: Dictionary[String, String] = {}

static func parse(json_definition: Dictionary) -> STF_Info:
	var ret = STF_Info.new()
	if("stf" not in json_definition):
		return null
	var stf = json_definition["stf"]
	if("root" not in stf):
		return null
	ret.root = stf["root"]
	ret.definition_version_major = stf.get("version_major")
	ret.definition_version_minor = stf.get("version_minor")
	ret.generator = stf.get("generator")
	ret.generator_version = stf.get("generator_version")
	ret.timestamp = stf.get("timestamp")
	ret.metric_multiplier = stf.get("metric_multiplier")

	# todo more
	return ret


# todo serialize
