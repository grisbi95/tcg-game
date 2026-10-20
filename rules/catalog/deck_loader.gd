class_name DeckLoader
extends RefCounted
## Charge les fichiers JSON de `data/decks/` (décision 0037).
##
## Un fichier est un objet `{"edition": "0.36", "id": …, "name": …, "hero": …, "cards": {id: n}}`.
## Le chargement ne lève jamais : `find_errors()` rend tout ce qui est faux, lecture, JSON, édition
## et champs. Les cartes et le Hero se contrôlent contre le catalogue au démarrage du duel
## (`DuelSetup.find_errors`).

const MINIMUM_COPIES: int = 1

var _decks: Array[DeckList] = []
var _expected_edition: String
var _errors: PackedStringArray = PackedStringArray()


## `expected_edition` vide : aucune édition imposée (Charte 9 : celle du catalogue, en jeu).
func _init(expected_edition: String = "") -> void:
	_expected_edition = expected_edition


## Decks chargés, dans l'ordre des fichiers.
func get_decks() -> Array[DeckList]:
	return _decks


## Deck d'identifiant `deck_id` ; null s'il n'a pas été chargé.
func find_deck(deck_id: StringName) -> DeckList:
	for deck: DeckList in _decks:
		if deck.deck_id == deck_id:
			return deck
	return null


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


func find_errors() -> PackedStringArray:
	return _errors.duplicate()


func _load_dictionary(data: Dictionary, source: String) -> void:
	var reader := CatalogReader.new(data)
	for key: String in ["edition", "id", "hero", "cards"]:
		reader.require(key, "0037")
	var deck := DeckList.new()
	var file_edition := reader.read_string("edition")
	deck.deck_id = StringName(reader.read_string("id"))
	deck.deck_name = reader.read_string("name")
	deck.hero_id = StringName(reader.read_string("hero"))
	_read_copies(reader, deck)
	for message: String in reader.finish():
		_errors.append("%s : %s" % [source, message])
	var is_edition_checked := not _expected_edition.is_empty() and not file_edition.is_empty()
	if is_edition_checked and file_edition != _expected_edition:
		_errors.append("%s : édition %s, attendue %s" % [source, file_edition, _expected_edition])
	if find_deck(deck.deck_id) != null:
		_errors.append("%s : deck « %s » déjà chargé" % [source, deck.deck_id])
		return
	_decks.append(deck)


func _read_copies(reader: CatalogReader, deck: DeckList) -> void:
	var cards := reader.read_object("cards")
	for card_id: Variant in cards:
		var count_reader := CatalogReader.new({str(card_id): cards[card_id]})
		var count := count_reader.read_int(str(card_id), MINIMUM_COPIES, 0)
		for message: String in count_reader.errors:
			reader.fail("cards : " + message)
		if count >= MINIMUM_COPIES:
			deck.copies[StringName(str(card_id))] = count
