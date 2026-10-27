extends SceneTree
## Rend les silhouettes provisoires des cartes (décision 0072) : chaque SVG de
## `docs/direction-artistique/silhouettes/` devient `assets/cards/art/<id>.webp`, en 1024 × 1024.
## Depuis la racine du projet, puis réimporter :
## "$GODOT_BIN" --headless --path . -s tools/render_card_art.gd

const SOURCE_DIRECTORY: String = "res://docs/direction-artistique/silhouettes/"
const SOURCE_EXTENSION: String = "svg"
const ART_SIDE: int = 1024
const VIEWBOX_SIDE: int = 1024
const WEBP_LOSSLESS: bool = true
const EXIT_FAILURE: int = 1


func _init() -> void:
	var target_directory := DuelAssets.CARD_ART_DIRECTORY
	if DirAccess.make_dir_recursive_absolute(target_directory) != OK:
		push_error("Dossier impossible à créer : %s" % target_directory)
		quit(EXIT_FAILURE)
		return
	var rendered_count := 0
	for file_name: String in DirAccess.get_files_at(SOURCE_DIRECTORY):
		if file_name.get_extension() != SOURCE_EXTENSION:
			continue
		if not _render(file_name.get_basename()):
			quit(EXIT_FAILURE)
			return
		rendered_count += 1
	print("Illustrations rendues : %d" % rendered_count)
	quit()


func _render(definition_id: String) -> bool:
	var source_path := SOURCE_DIRECTORY + definition_id + "." + SOURCE_EXTENSION
	var image := Image.new()
	var scale := float(ART_SIDE) / float(VIEWBOX_SIDE)
	var error := image.load_svg_from_string(FileAccess.get_file_as_string(source_path), scale)
	if error != OK or image.get_width() != ART_SIDE or image.get_height() != ART_SIDE:
		push_error("Rendu impossible : %s" % source_path)
		return false
	var target_path := DuelAssets.card_art_path(StringName(definition_id))
	if image.save_webp(target_path, WEBP_LOSSLESS) != OK:
		push_error("Écriture impossible : %s" % target_path)
		return false
	return true
