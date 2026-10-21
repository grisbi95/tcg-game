class_name DuelJournal
extends RefCounted
## Journal d'un duel (décisions 0022 et 0042) : préparation, puis, dans l'ordre, intentions
## acceptées, temps réel écoulé, temps écoulé pendant la fenêtre de réponse d'un joueur et
## réponses commencées. S'écrit et se lit en JSON ; se rejoue dans un moteur neuf, à l'identique
## (déterminisme, décision 0001) ; la fiche de playtest s'en déduit (`PlaytestRecorder`).

## Sortes d'entrées, écrites en JSON par leurs clés, jamais par leur numéro.
enum EntryKind {
	INTENT,
	ELAPSED_TIME,
	RESPONSE_WINDOW_TIME,
	RESPONSE_BEGUN,
}

## Version du format JSON ; un journal d'une autre version est refusé à la lecture.
const FORMAT_VERSION: int = 2


## Une intention acceptée, du temps écoulé, du temps écoulé pendant la fenêtre de réponse de
## `player`, ou une réponse commencée par `player` (208.6.5).
class Entry:
	extends RefCounted
	var kind: EntryKind = EntryKind.INTENT
	var intent: DuelIntent = null
	var elapsed_msec: int = 0
	## Joueur de la fenêtre de réponse ; sans objet pour une intention et le temps ordinaire.
	var player: DuelState.PlayerSide = DuelState.PlayerSide.A

	func is_intent() -> bool:
		return kind == EntryKind.INTENT

	## Temps qui fait avancer la pendule, hors ou pendant une fenêtre de réponse.
	func counts_time() -> bool:
		return kind == EntryKind.ELAPSED_TIME or kind == EntryKind.RESPONSE_WINDOW_TIME


var ruleset_edition: String = ""
var setup: DuelSetup = DuelSetup.new()
var entries: Array[Entry] = []


## Garde une copie de `duel_setup` : l'appelant peut ensuite le modifier sans changer le journal.
func _init(duel_setup: DuelSetup = DuelSetup.new(), edition: String = "") -> void:
	setup = _decode_setup(_encode_setup(duel_setup))
	ruleset_edition = edition


## Garde une copie de `intent`, comme `_init()` pour la préparation.
func record_intent(intent: DuelIntent) -> void:
	var entry := Entry.new()
	entry.intent = IntentCodec.decode(IntentCodec.encode(intent))
	entries.append(entry)


## Les temps consécutifs se cumulent : les pendules qui tournent ne changent qu'à une soumission.
func record_elapsed(elapsed_msec: int) -> void:
	_record_time(EntryKind.ELAPSED_TIME, DuelState.PlayerSide.A, elapsed_msec)


## 208.6.2, décision 0042 : temps écoulé pendant la fenêtre de réponse montrée à `player` ; les
## temps consécutifs d'un même joueur se cumulent.
func record_response_window_elapsed(player: DuelState.PlayerSide, elapsed_msec: int) -> void:
	_record_time(EntryKind.RESPONSE_WINDOW_TIME, player, elapsed_msec)


## 208.6.5, décision 0042 : `player` a commencé une réponse pendant sa fenêtre de réponse.
func record_response_begun(player: DuelState.PlayerSide) -> void:
	var entry := Entry.new()
	entry.kind = EntryKind.RESPONSE_BEGUN
	entry.player = player
	entries.append(entry)


## Décision 0036 : durée du duel affichée en fin de partie, somme des temps écoulés.
func total_elapsed_msec() -> int:
	var total_msec := 0
	for entry: Entry in entries:
		if entry.counts_time():
			total_msec += entry.elapsed_msec
	return total_msec


## Temps de pendule écoulé pendant les fenêtres de réponse montrées à `player` (208.6.2).
func response_window_elapsed_msec(player: DuelState.PlayerSide) -> int:
	var total_msec := 0
	for entry: Entry in entries:
		if entry.kind == EntryKind.RESPONSE_WINDOW_TIME and entry.player == player:
			total_msec += entry.elapsed_msec
	return total_msec


## Nombre de réponses que `player` a commencées pendant une fenêtre de réponse (208.6.5).
func response_begun_count(player: DuelState.PlayerSide) -> int:
	var count := 0
	for entry: Entry in entries:
		if entry.kind == EntryKind.RESPONSE_BEGUN and entry.player == player:
			count += 1
	return count


## Rejoue le duel dans `engine`, neuf, et renvoie tous ses événements, dans l'ordre.
func replay_into(engine: DuelEngine) -> Array[DuelEvent]:
	var events := engine.start_new_duel(setup)
	for entry: Entry in entries:
		events.append_array(replay_entry(engine, entry))
	return events


## Rejoue une entrée dans `engine` : une intention est soumise, un temps avance la pendule, une
## réponse commencée ne change rien au moteur.
static func replay_entry(engine: DuelEngine, entry: Entry) -> Array[DuelEvent]:
	if entry.counts_time():
		return engine.advance_clock(entry.elapsed_msec)
	if entry.is_intent():
		return engine.submit(entry.intent)
	return []


func to_json() -> String:
	var encoded_entries: Array[Dictionary] = []
	for entry: Entry in entries:
		encoded_entries.append(_encode_entry(entry))
	var data := {
		"format_version": FORMAT_VERSION,
		"ruleset_edition": ruleset_edition,
		"setup": _encode_setup(setup),
		"entries": encoded_entries,
	}
	return JSON.stringify(data, "\t")


## Journal lu dans `text`, ou null si `find_errors(text)` n'est pas vide.
static func from_json(text: String) -> DuelJournal:
	return _parse(text, PackedStringArray())


## Raisons qui empêchent de lire `text` ; vide si le journal est lisible.
static func find_errors(text: String) -> PackedStringArray:
	var errors := PackedStringArray()
	_parse(text, errors)
	return errors


func _record_time(kind: EntryKind, player: DuelState.PlayerSide, elapsed_msec: int) -> void:
	if elapsed_msec <= 0:
		return
	if not entries.is_empty():
		var last_entry: Entry = entries.back()
		if last_entry.kind == kind and last_entry.player == player:
			last_entry.elapsed_msec += elapsed_msec
			return
	var entry := Entry.new()
	entry.kind = kind
	entry.player = player
	entry.elapsed_msec = elapsed_msec
	entries.append(entry)


static func _parse(text: String, errors: PackedStringArray) -> DuelJournal:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		errors.append("journal illisible : JSON attendu")
		return null
	var data: Dictionary = parsed
	var version: Variant = data.get("format_version")
	if not (JsonValues.is_number(version) and JsonValues.to_int(version) == FORMAT_VERSION):
		errors.append("version du format %s, attendue %d" % [version, FORMAT_VERSION])
		return null
	var duel_setup := _decode_setup(data.get("setup"))
	if duel_setup == null:
		errors.append("préparation absente ou mal formée")
		return null
	var journal := DuelJournal.new(duel_setup, str(data.get("ruleset_edition")))
	journal._decode_entries(data.get("entries"), errors)
	return journal if errors.is_empty() else null


func _decode_entries(encoded_entries: Variant, errors: PackedStringArray) -> void:
	if not encoded_entries is Array:
		errors.append("entrées absentes")
		return
	var items: Array = encoded_entries
	for index: int in items.size():
		var entry := _decode_entry(items[index])
		if entry == null:
			errors.append("entrée %d mal formée" % index)
			return
		entries.append(entry)


static func _encode_entry(entry: Entry) -> Dictionary:
	match entry.kind:
		EntryKind.INTENT:
			return {"intent": IntentCodec.encode(entry.intent)}
		EntryKind.RESPONSE_WINDOW_TIME:
			return {"response_window_elapsed_msec": entry.elapsed_msec, "player": entry.player}
		EntryKind.RESPONSE_BEGUN:
			return {"response_begun": true, "player": entry.player}
	return {"elapsed_msec": entry.elapsed_msec}


# null si l'entrée n'est d'aucune sorte connue ou si un champ manque ou est mal formé.
static func _decode_entry(encoded: Variant) -> Entry:
	if not encoded is Dictionary:
		return null
	var data: Dictionary = encoded
	var entry := Entry.new()
	if data.has("intent"):
		return _decode_intent_entry(data, entry)
	if data.get("response_begun") == true:
		entry.kind = EntryKind.RESPONSE_BEGUN
		return entry if _read_player(data, entry) else null
	if data.has("response_window_elapsed_msec"):
		entry.kind = EntryKind.RESPONSE_WINDOW_TIME
		var is_well_formed := (
			_read_elapsed(data.get("response_window_elapsed_msec"), entry)
			and _read_player(data, entry)
		)
		return entry if is_well_formed else null
	entry.kind = EntryKind.ELAPSED_TIME
	return entry if _read_elapsed(data.get("elapsed_msec"), entry) else null


static func _decode_intent_entry(data: Dictionary, entry: Entry) -> Entry:
	var intent_data: Variant = data.get("intent")
	if not intent_data is Dictionary:
		return null
	var intent_fields: Dictionary = intent_data
	entry.intent = IntentCodec.decode(intent_fields)
	return entry if entry.intent != null else null


static func _read_elapsed(elapsed: Variant, entry: Entry) -> bool:
	if not (JsonValues.is_number(elapsed) and JsonValues.to_int(elapsed) > 0):
		return false
	entry.elapsed_msec = JsonValues.to_int(elapsed)
	return true


static func _read_player(data: Dictionary, entry: Entry) -> bool:
	var side: Variant = data.get("player")
	if not (
		JsonValues.is_number(side) and DuelState.PlayerSide.values().has(JsonValues.to_int(side))
	):
		return false
	entry.player = JsonValues.to_int(side) as DuelState.PlayerSide
	return true


# La graine s'écrit en texte : un nombre JSON n'est exact que jusqu'à 2^53.
static func _encode_setup(duel_setup: DuelSetup) -> Dictionary:
	return {
		"deck_a": Array(duel_setup.deck_a),
		"deck_b": Array(duel_setup.deck_b),
		"hero_a": String(duel_setup.hero_a),
		"hero_b": String(duel_setup.hero_b),
		"rng_seed": str(duel_setup.rng_seed),
		"is_first_player_imposed": duel_setup.is_first_player_imposed,
		"imposed_first_player": duel_setup.imposed_first_player,
	}


# null si la préparation ou l'un de ses champs manque ou est mal formé.
static func _decode_setup(encoded: Variant) -> DuelSetup:
	if not encoded is Dictionary:
		return null
	var data: Dictionary = encoded
	var duel_setup := DuelSetup.new()
	var seed_text := str(data.get("rng_seed"))
	var side: Variant = data.get("imposed_first_player")
	var is_imposed: Variant = data.get("is_first_player_imposed")
	var hero_a: Variant = data.get("hero_a")
	var hero_b: Variant = data.get("hero_b")
	var is_well_formed := (
		_read_card_ids(data.get("deck_a"), duel_setup.deck_a)
		and _read_card_ids(data.get("deck_b"), duel_setup.deck_b)
		and hero_a is String
		and hero_b is String
		and seed_text.is_valid_int()
		and is_imposed is bool
		and JsonValues.is_number(side)
		and DuelState.PlayerSide.values().has(JsonValues.to_int(side))
	)
	if not is_well_formed:
		return null
	duel_setup.hero_a = StringName(str(hero_a))
	duel_setup.hero_b = StringName(str(hero_b))
	duel_setup.rng_seed = seed_text.to_int()
	if is_imposed:
		duel_setup.impose_first_player(JsonValues.to_int(side) as DuelState.PlayerSide)
	return duel_setup


static func _read_card_ids(encoded: Variant, card_ids: Array[StringName]) -> bool:
	if not encoded is Array:
		return false
	for card_id: Variant in encoded:
		if not (card_id is String or card_id is StringName):
			return false
		card_ids.append(StringName(str(card_id)))
	return true
