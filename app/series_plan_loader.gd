class_name SeriesPlanLoader
extends RefCounted
## Charge le plan de série de `data/series/` (décision 0069).
##
## Le fichier est un objet `{"edition": "0.56", "games": [{"game": 1, "deck_a": …, "deck_b": …,
## "first_player": "A"}, …]}`. Le chargement ne lève jamais : `find_errors()` rend tout ce qui est
## faux, lecture, JSON, édition, nombre de parties, champs, deck inconnu, numéro manquant ou en
## double.

const DECISION: String = "0069"
## Aucun nombre de parties imposé.
const ANY_GAME_COUNT: int = 0
const FIRST_PLAYER_LETTERS: Dictionary[String, DuelState.PlayerSide] = {
	"A": DuelState.PlayerSide.A,
	"B": DuelState.PlayerSide.B,
}

var _plan: SeriesPlan = SeriesPlan.new()
var _expected_edition: String
var _known_deck_ids: Array[StringName]
var _expected_game_count: int
var _errors: PackedStringArray = PackedStringArray()


## `expected_edition` vide : aucune édition imposée ; `known_deck_ids` : decks de `data/decks/` ;
## `expected_game_count` : nombre de parties du plan, `ANY_GAME_COUNT` pour n'en imposer aucun.
func _init(
	expected_edition: String,
	known_deck_ids: Array[StringName],
	expected_game_count: int = ANY_GAME_COUNT
) -> void:
	_expected_edition = expected_edition
	_known_deck_ids = known_deck_ids
	_expected_game_count = expected_game_count


func get_plan() -> SeriesPlan:
	return _plan


func find_errors() -> PackedStringArray:
	return _errors.duplicate()


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


func _load_dictionary(data: Dictionary, source: String) -> void:
	var reader := CatalogReader.new(data)
	for key: String in ["edition", "games"]:
		reader.require(key, DECISION)
	_plan.edition = reader.read_string("edition")
	for game_data: Dictionary in reader.read_objects("games"):
		_read_game(game_data, reader)
	for message: String in reader.finish():
		_errors.append("%s : %s" % [source, message])
	var is_edition_checked := not _expected_edition.is_empty() and not _plan.edition.is_empty()
	if is_edition_checked and _plan.edition != _expected_edition:
		_errors.append("%s : édition %s, attendue %s" % [source, _plan.edition, _expected_edition])
	var is_count_checked := _expected_game_count != ANY_GAME_COUNT
	if is_count_checked and _plan.game_count() != _expected_game_count:
		_errors.append(
			"%s : %d parties, attendues %d" % [source, _plan.game_count(), _expected_game_count]
		)
	for message: String in _find_numbering_errors():
		_errors.append("%s : %s" % [source, message])
	_plan.games.sort_custom(_is_numbered_before)


func _read_game(game_data: Dictionary, plan_reader: CatalogReader) -> void:
	var reader := CatalogReader.new(game_data)
	for key: String in ["game", "deck_a", "deck_b", "first_player"]:
		reader.require(key, DECISION)
	var game := SeriesPlanGame.new()
	game.game_number = reader.read_int("game", SeriesPlan.FIRST_GAME_NUMBER, 0)
	game.deck_id_a = _read_deck_id(reader, "deck_a")
	game.deck_id_b = _read_deck_id(reader, "deck_b")
	var letter := reader.read_string("first_player")
	if FIRST_PLAYER_LETTERS.has(letter):
		game.first_player = FIRST_PLAYER_LETTERS[letter]
	elif reader.has("first_player"):
		reader.fail("« first_player » : « %s » inconnu (valeurs : A, B)" % letter)
	for message: String in reader.finish():
		plan_reader.fail("partie %d : %s" % [game.game_number, message])
	_plan.games.append(game)


func _read_deck_id(reader: CatalogReader, key: String) -> StringName:
	var deck_id := StringName(reader.read_string(key))
	if reader.has(key) and not _known_deck_ids.has(deck_id):
		reader.fail("« %s » : deck « %s » inconnu" % [key, deck_id])
	return deck_id


# Les numéros vont de 1 au nombre de parties, chacun une fois.
func _find_numbering_errors() -> PackedStringArray:
	var messages := PackedStringArray()
	var counts: Dictionary[int, int] = {}
	for game: SeriesPlanGame in _plan.games:
		counts[game.game_number] = counts.get(game.game_number, 0) + 1
	for game_number: int in counts:
		if counts[game_number] > 1:
			messages.append("partie %d en double" % game_number)
	var last_number := SeriesPlan.FIRST_GAME_NUMBER + _plan.game_count() - 1
	for game_number: int in range(SeriesPlan.FIRST_GAME_NUMBER, last_number + 1):
		if not counts.has(game_number):
			messages.append("partie %d manquante" % game_number)
	return messages


static func _is_numbered_before(first: SeriesPlanGame, second: SeriesPlanGame) -> bool:
	return first.game_number < second.game_number
