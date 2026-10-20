class_name CatalogLoader
extends RefCounted
## Charge les fichiers JSON de `data/cards/` dans un Catalog (décisions 0002 et 0010).
##
## Un fichier est un objet `{"edition": "0.28", "heroes": [...], "cards": [...]}`. Le chargement
## ne lève jamais : `find_errors()` rend tout ce qui est faux, lecture, JSON, édition et
## définitions. Un catalogue qui renvoie des erreurs ne doit pas servir au moteur.

var _catalog: Catalog = Catalog.new()
var _expected_edition: String
var _errors: PackedStringArray = PackedStringArray()


## `expected_edition` vide : les fichiers doivent seulement s'accorder entre eux.
func _init(expected_edition: String = "") -> void:
	_expected_edition = expected_edition


func get_catalog() -> Catalog:
	return _catalog


## Charge chaque `.json` du dossier, par ordre alphabétique.
func load_directory(directory_path: String) -> void:
	for path: String in JsonObjectFiles.file_paths(directory_path, _errors):
		load_file(path)


func load_file(path: String) -> void:
	var error_count := _errors.size()
	var json_text := JsonObjectFiles.read_text(path, _errors)
	if _errors.size() == error_count:
		load_text(json_text, path)


## `source` nomme le fichier d'origine dans les messages.
func load_text(json_text: String, source: String) -> void:
	var error_count := _errors.size()
	var data := JsonObjectFiles.parse_object(json_text, source, _errors)
	if _errors.size() == error_count:
		_load_dictionary(data, source)


## Erreurs de lecture et d'édition, puis erreurs du catalogue.
func find_errors() -> PackedStringArray:
	var errors := _errors.duplicate()
	errors.append_array(_catalog.find_errors())
	return errors


func _load_dictionary(data: Dictionary, source: String) -> void:
	var reader := CatalogReader.new(data)
	reader.require("edition", "CHARTE 9")
	var file_edition := reader.read_string("edition")
	var hero_entries := reader.read_array("heroes")
	var card_entries := reader.read_array("cards")
	for message: String in reader.finish():
		_errors.append("%s : %s" % [source, message])
	_check_edition(file_edition, source)
	for entry: Variant in hero_entries:
		_add_hero(entry, source)
	for entry: Variant in card_entries:
		_add_card(entry, source)


# Charte 9 : un fichier porte l'édition du ruleset qu'il suit.
func _check_edition(file_edition: String, source: String) -> void:
	if file_edition.is_empty():
		return
	if not _expected_edition.is_empty() and file_edition != _expected_edition:
		_errors.append("%s : édition %s, attendue %s" % [source, file_edition, _expected_edition])
	if _catalog.edition.is_empty():
		_catalog.edition = file_edition
	elif file_edition != _catalog.edition:
		_errors.append(
			"%s : édition %s, les fichiers précédents %s" % [source, file_edition, _catalog.edition]
		)


func _add_hero(entry: Variant, source: String) -> void:
	if typeof(entry) != TYPE_DICTIONARY:
		_errors.append("%s : chaque entrée de « heroes » est un objet" % source)
		return
	var entry_dict: Dictionary = entry
	_catalog.add_hero(HeroDefinition.from_dict(entry_dict))


func _add_card(entry: Variant, source: String) -> void:
	if typeof(entry) != TYPE_DICTIONARY:
		_errors.append("%s : chaque entrée de « cards » est un objet" % source)
		return
	var entry_dict: Dictionary = entry
	_catalog.add_card(CardDefinition.from_dict(entry_dict))
