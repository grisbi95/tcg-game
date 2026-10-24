extends GdUnitTestSuite
## Assets du jeu (décision 0051) : rangement de `assets/`, registre de provenance, noms reliés aux
## cartes et aux icônes, réglages d'import pour le Web, repli quand un asset manque.

const REGISTRY_PATH: String = "res://assets/REGISTRE.md"
const REGISTRY_FILE_NAME: String = "REGISTRE.md"
const REGISTRY_FILES_HEADING: String = "## Fichiers"
const REGISTRY_ROW_PREFIX: String = "| `"
const IMPORT_EXTENSION: String = ".import"
const UID_EXTENSION: String = ".uid"
const FILE_NAME_PATTERN: String = "^[a-z0-9]+(_[a-z0-9]+)*\\.[a-z0-9]+$"
const IMAGE_EXTENSIONS: Array[String] = ["webp", "png", "svg"]
const RASTER_EXTENSIONS: Array[String] = ["webp", "png"]
const MAX_IMAGE_SIDE: int = 1024
const IMPORT_COMPRESS_MODE: String = "compress/mode"
const IMPORT_MIPMAPS: String = "mipmaps/generate"
## Valeurs de `compress/mode` d'un `.import` de `CompressedTexture2D`.
const COMPRESS_LOSSLESS: int = 0
const COMPRESS_LOSSY: int = 1
## Les modes VRAM sont exclus (Web).
const ALLOWED_COMPRESS_MODES: Array[int] = [COMPRESS_LOSSLESS, COMPRESS_LOSSY]


func test_decision_0051_missing_card_art_gives_no_texture() -> void:
	assert_object(DuelAssets.card_art(&"carte_sans_illustration")).is_null()
	assert_object(DuelAssets.card_art(&"")).is_null()


func test_decision_0051_missing_icon_gives_no_texture() -> void:
	assert_object(DuelAssets.icon("icone_absente")).is_null()


func test_decision_0051_card_art_is_named_by_the_definition_id() -> void:
	assert_str(DuelAssets.card_art_path(&"recrue")).is_equal("res://assets/cards/art/recrue.webp")


func test_decision_0051_icon_assets_are_named_after_duel_icons() -> void:
	assert_str(DuelIcons.asset_name(DuelIcons.Icon.UNIT)).is_equal("unit")
	assert_str(DuelIcons.asset_name(DuelIcons.Icon.SOURCE)).is_equal("source")


func test_decision_0051_registry_exists() -> void:
	assert_bool(FileAccess.file_exists(REGISTRY_PATH)).is_true()


func test_decision_0051_file_names_are_snake_case() -> void:
	var pattern := RegEx.create_from_string(FILE_NAME_PATTERN)
	for path: String in _asset_files():
		assert_object(pattern.search(path.get_file())).override_failure_message(path).is_not_null()


func test_decision_0051_every_asset_is_registered() -> void:
	var registered := _registered_files()
	for path: String in _asset_files():
		assert_bool(registered.has(path)).override_failure_message(path).is_true()


func test_decision_0051_every_registered_asset_exists() -> void:
	for path: String in _registered_files():
		var full_path := DuelAssets.ROOT_DIRECTORY + path
		assert_bool(FileAccess.file_exists(full_path)).override_failure_message(path).is_true()


func test_decision_0051_card_art_names_a_card_or_a_hero() -> void:
	var catalog := GameLibrary.load_catalog()
	for path: String in _files_in(DuelAssets.CARD_ART_DIRECTORY):
		var id := StringName(path.get_file().get_basename())
		var is_known := catalog.get_card(id) != null or catalog.get_hero(id) != null
		assert_bool(is_known).override_failure_message(path).is_true()
		assert_str(path.get_extension()).is_equal(DuelAssets.CARD_ART_EXTENSION.trim_prefix("."))


func test_decision_0051_icons_name_a_duel_icon() -> void:
	var names: Array[String] = []
	for icon: int in DuelIcons.Icon.values():
		names.append(DuelIcons.asset_name(icon as DuelIcons.Icon))
	for path: String in _files_in(DuelAssets.ICON_DIRECTORY):
		var icon_name := path.get_file().get_basename()
		assert_bool(names.has(icon_name)).override_failure_message(path).is_true()
		assert_str(path.get_extension()).is_equal(DuelAssets.ICON_EXTENSION.trim_prefix("."))


func test_decision_0051_images_are_imported_for_the_web() -> void:
	for path: String in _asset_files():
		if not IMAGE_EXTENSIONS.has(path.get_extension()):
			continue
		var settings := ConfigFile.new()
		var full_path := DuelAssets.ROOT_DIRECTORY + path
		var error := settings.load(full_path + IMPORT_EXTENSION)
		assert_int(error).override_failure_message(path).is_equal(OK)
		var mode: int = settings.get_value("params", IMPORT_COMPRESS_MODE, -1)
		assert_bool(ALLOWED_COMPRESS_MODES.has(mode)).override_failure_message(path).is_true()
		var mipmaps: bool = settings.get_value("params", IMPORT_MIPMAPS, true)
		assert_bool(mipmaps).override_failure_message(path).is_false()


func test_decision_0051_raster_images_stay_under_the_maximum_side() -> void:
	for path: String in _asset_files():
		if not RASTER_EXTENSIONS.has(path.get_extension()):
			continue
		var texture: Texture2D = load(DuelAssets.ROOT_DIRECTORY + path)
		var side := maxi(texture.get_width(), texture.get_height())
		assert_int(side).override_failure_message(path).is_less_equal(MAX_IMAGE_SIDE)


## Fichiers de `assets/`, relatifs au dossier, hors registre et fichiers de Godot.
func _asset_files() -> Array[String]:
	var files: Array[String] = []
	for path: String in _files_in(DuelAssets.ROOT_DIRECTORY):
		if path != REGISTRY_FILE_NAME:
			files.append(path)
	return files


## Fichiers sous `directory`, relatifs à `assets/`, en descendant dans les sous-dossiers.
func _files_in(directory: String) -> Array[String]:
	var files: Array[String] = []
	if not DirAccess.dir_exists_absolute(directory):
		return files
	var relative := directory.trim_prefix(DuelAssets.ROOT_DIRECTORY)
	for file_name: String in DirAccess.get_files_at(directory):
		if _is_asset_file(file_name):
			files.append(relative + file_name)
	for child: String in DirAccess.get_directories_at(directory):
		files.append_array(_files_in(directory + child + "/"))
	return files


func _is_asset_file(file_name: String) -> bool:
	return not (
		file_name.begins_with(".")
		or file_name.ends_with(IMPORT_EXTENSION)
		or file_name.ends_with(UID_EXTENSION)
	)


## Fichiers nommés en première colonne du tableau « Fichiers » du registre.
func _registered_files() -> Array[String]:
	var files: Array[String] = []
	var is_in_files_section := false
	for line: String in FileAccess.get_file_as_string(REGISTRY_PATH).split("\n"):
		if line.begins_with("## "):
			is_in_files_section = line.strip_edges() == REGISTRY_FILES_HEADING
		elif is_in_files_section and line.begins_with(REGISTRY_ROW_PREFIX):
			files.append(line.trim_prefix(REGISTRY_ROW_PREFIX).get_slice("`", 0))
	return files
