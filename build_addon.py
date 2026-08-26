
import io

ADDON_NAME = "stf_godot.zip"

def build_godot_addon(package_buffer: io.BytesIO):
	"""
	Builds a Godot addon .zip package.

	Easy to use from the commandline, and more importantly, easily usable in a git-ops action.
	"""
	path_include_patterns: list[str] = []
	path_include_patterns.append("addons/stf_godot/**/*")

	from pathspec import GitIgnoreSpec
	spec = GitIgnoreSpec.from_lines(path_include_patterns)
	files_to_add = set(spec.match_tree_files(".", negate=False))

	import zipfile
	with zipfile.ZipFile(package_buffer, mode="w") as package:
		for file in files_to_add:
			package.write(file)

if(__name__ == "__main__"):
	import argparse
	parser = argparse.ArgumentParser(description="Build Godot Addon")
	parser.add_argument("-o", "--output-dir", help="Directory where to place the addon .zip", default=".")

	args = parser.parse_args()

	import os
	with open(os.path.join(args.output_dir, ADDON_NAME), "wb") as package_buffer:
		build_godot_addon(package_buffer) # pyright: ignore[reportArgumentType]
