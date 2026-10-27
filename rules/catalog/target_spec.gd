class_name TargetSpec
extends RefCounted
## Cible que choisit un effet (207.5, décisions 0002, 0010 et 0062) : ce qui se vise et les
## filtres. Les filtres de pièce sont ceux d'un PieceFilter, partagé avec la portée d'un effet
## statique ; la Force maximale, les filtres de case (rangée, adjacence, cases distinctes) et ceux
## du Spell ciblé (coût, vitesse) restent ici.
##
## Un effet statique ne cible pas (207.2.1, 207.5.1) : il a une portée, un PieceFilter. La validité
## à l'ajout à la pile et à la résolution est jugée par le module du chapitre 207.

## 207.5.11, 207.5.14 : ce qu'un effet peut cibler. Enum journalisable : ajouter à la fin.
enum TargetWhat {
	PIECE,  # 207.5.11 : Hero, jeton compris (207.5.11a, 207.5.11b)
	CELL,  # 207.5.11, 202.4.12
	SPELL_ON_STACK,  # 207.5.14
}

## Filtre d'adjacence d'une case ciblée (décision 0056) ; celui d'une pièce est dans PieceFilter.
## Enum journalisable : ajouter à la fin.
enum AdjacentTo {
	NONE,
	TARGET_PIECE,  # case adjacente à la pièce que cible le même effet (destination, 215.1.1)
	SOURCE_PIECE,  # adjacente à la case de la pièce qui porte l'effet, ou à sa dernière (207.3.14)
}

## Valeur de `max_force` quand la Force de la cible n'est pas bornée.
const NO_FORCE_LIMIT: int = -1
## Valeur de `spell_max_cost` quand le coût du Spell ciblé n'est pas borné.
const NO_COST_LIMIT: int = -1
const MIN_TARGET_COUNT: int = 1  # 207.5.10
const MIN_DISTINCT_COUNT: int = 2  # des cibles distinctes se comptent à partir de deux

var what: TargetWhat = TargetWhat.PIECE
## Filtre de la pièce visée (décision 0062) ; sans objet pour une case ou un Spell.
var piece_filter: PieceFilter = PieceFilter.new()
## Borne haute de la Force actuelle de la cible (« de Force 3 ou moins »).
var max_force: int = NO_FORCE_LIMIT
## Décision 0058, 213.1.10 : `max_force` s'écrit « X » ; la valeur vient de `x_from` de l'effet,
## et `with_x()` en fait une borne chiffrée.
var max_force_is_x: bool = false
## Zone de la case visée (205.1.2 à 205.1.4), pour une case seulement ; celle d'une pièce est dans
## `piece_filter`.
var row: PieceFilter.RowZone = PieceFilter.RowZone.ANY
var adjacent_to: AdjacentTo = AdjacentTo.NONE
## Les cibles de ce genre que choisit l'effet sont deux à deux différentes : pratique de rédaction
## « distinctes » écrite par la carte ; la règle générale reste Q-098.
var distinct: bool = false
## 207.5.6, 213.1.6 : borne haute du coût actuel du Spell ciblé, X compris.
var spell_max_cost: int = NO_COST_LIMIT
## 207.1.2 : vitesses admises du Spell ciblé ; vide : toutes.
var spell_speeds: Array[CardDefinition.SpellSpeed] = []
var count_min: int = MIN_TARGET_COUNT
var count_max: int = MIN_TARGET_COUNT
## 207.3.14 : pièce source et sa case, pour un filtre relatif à la pièce qui porte l'effet
## (`with_source`), lues à l'exécution, jamais du JSON.
var source_piece_id: int = DuelState.NO_ID
var source_cell: Vector2i = BoardGeometry.NO_CELL
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Lit une cible depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> TargetSpec:
	var spec := TargetSpec.new()
	var reader := CatalogReader.new(data)
	reader.require("what", "207.5.11")
	var what_value := reader.read_enum("what", TargetWhat)
	if what_value != CatalogReader.NOT_SET:
		spec.what = what_value as TargetWhat
	if reader.has("filter"):
		spec.piece_filter = PieceFilter.from_dict(reader.read_object("filter"))
	var row_value := reader.read_enum("row", PieceFilter.RowZone)
	if row_value != CatalogReader.NOT_SET:
		spec.row = row_value as PieceFilter.RowZone
	var adjacent_value := reader.read_enum("adjacent_to", AdjacentTo)
	if adjacent_value != CatalogReader.NOT_SET:
		spec.adjacent_to = adjacent_value as AdjacentTo
	spec.distinct = reader.read_bool("distinct", false)
	spec._read_spell_filters(reader)
	spec.max_force_is_x = reader.is_x("max_force")
	if not spec.max_force_is_x:
		spec.max_force = reader.read_int(
			"max_force", CatalogReader.NON_NEGATIVE_MINIMUM, NO_FORCE_LIMIT
		)
	spec.count_min = reader.read_int(
		"count_min", CatalogReader.NON_NEGATIVE_MINIMUM, MIN_TARGET_COUNT
	)
	spec.count_max = reader.read_int(
		"count_max", CatalogReader.NON_NEGATIVE_MINIMUM, spec.count_min
	)
	spec.parse_errors = reader.finish()
	return spec


# 207.5.10 : le nombre de cibles est borné par la carte ; chaque filtre ne vaut que pour ce qu'il
# filtre (207.5.11, 202.3.9).
func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	for message: String in piece_filter.find_errors():
		errors.append("filter : " + message)
	match what:
		TargetWhat.PIECE:
			_check_piece(errors)
		TargetWhat.CELL:
			_check_cell(errors)
		TargetWhat.SPELL_ON_STACK:
			_check_spell_on_stack(errors)
	if count_min < MIN_TARGET_COUNT or count_max < count_min:
		errors.append("207.5.10 : count_min au moins 1 et count_max au moins count_min")
	if distinct and count_max < MIN_DISTINCT_COUNT:
		errors.append("207.5.10 : distinct exige count_max au moins 2")
	return errors


## 213.1.10, 213.1.11 : cette cible où « X » vaut `x_value` ; `self` si elle n'a pas de X.
func with_x(x_value: int) -> TargetSpec:
	if not max_force_is_x:
		return self
	var copy := _copy()
	copy.max_force = x_value
	copy.max_force_is_x = false
	return copy


## 207.3.14 : cette cible où les filtres relatifs à la pièce source se lisent par rapport à
## `piece_id`, sur la case `cell` ; `self` si elle n'en a pas.
func with_source(piece_id: int, cell: Vector2i) -> TargetSpec:
	if not uses_source_piece():
		return self
	var copy := _copy()
	copy.source_piece_id = piece_id
	copy.source_cell = cell
	return copy


## Vrai si la cible se lit par rapport à la pièce qui porte l'effet (207.3.14).
func uses_source_piece() -> bool:
	return piece_filter.uses_source_piece() or adjacent_to == AdjacentTo.SOURCE_PIECE


## Vrai si la Force de la cible est bornée, par un nombre ou par X.
func has_force_limit() -> bool:
	return max_force != NO_FORCE_LIMIT or max_force_is_x


## Vrai si un filtre du Spell ciblé est écrit.
func has_spell_filter() -> bool:
	return spell_max_cost != NO_COST_LIMIT or not spell_speeds.is_empty()


func _copy() -> TargetSpec:
	var copy := TargetSpec.new()
	copy.what = what
	copy.piece_filter = piece_filter  # jamais modifié après la lecture : partagé
	copy.max_force = max_force
	copy.max_force_is_x = max_force_is_x
	copy.row = row
	copy.adjacent_to = adjacent_to
	copy.distinct = distinct
	copy.spell_max_cost = spell_max_cost
	copy.spell_speeds.assign(spell_speeds)
	copy.count_min = count_min
	copy.count_max = count_max
	copy.source_piece_id = source_piece_id
	copy.source_cell = source_cell
	copy.parse_errors = parse_errors.duplicate()
	return copy


func _read_spell_filters(reader: CatalogReader) -> void:
	spell_max_cost = reader.read_int(
		"spell_max_cost", CatalogReader.NON_NEGATIVE_MINIMUM, NO_COST_LIMIT
	)
	for entry: Variant in reader.read_array("spell_speeds"):
		var text: String = entry if typeof(entry) == TYPE_STRING else ""
		var value := CatalogReader.enum_value(CardDefinition.SpellSpeed, text)
		if value == CatalogReader.NOT_SET or value == CardDefinition.SpellSpeed.NONE:
			reader.fail("« spell_speeds » : %s inconnu (action ou reaction)" % str(entry))
		else:
			spell_speeds.append(value as CardDefinition.SpellSpeed)


func _check_piece(errors: PackedStringArray) -> void:
	if piece_filter.piece_kinds.is_empty():
		errors.append("207.5.11 : une cible pièce nomme au moins un genre dans piece_kinds")
	if row != PieceFilter.RowZone.ANY:
		errors.append("207.5.11 : row de la cible ne vaut que pour une case, voir filter")
	if max_force < NO_FORCE_LIMIT:
		errors.append("207.5.11 : max_force est au moins 0")
	if has_force_limit() and piece_filter.piece_kinds.has(Piece.PieceKind.HERO):
		errors.append("202.3.9 : un Hero n'a pas de Force, max_force l'exclut des genres")
	if adjacent_to == AdjacentTo.TARGET_PIECE:
		errors.append("215.1.1 : target_piece ne vaut que pour une case de destination")
	elif adjacent_to != AdjacentTo.NONE:
		errors.append("207.5.11 : adjacent_to ne vaut que pour une case, voir filter")
	if has_spell_filter():
		errors.append("207.5.14 : spell_max_cost et spell_speeds ne valent que pour un Spell")


func _check_cell(errors: PackedStringArray) -> void:
	if not piece_filter.is_default() or has_force_limit():
		errors.append("207.5.11 : une case n'a ni filter, ni max_force")
	if has_spell_filter():
		errors.append("207.5.14 : spell_max_cost et spell_speeds ne valent que pour un Spell")


func _check_spell_on_stack(errors: PackedStringArray) -> void:
	if not piece_filter.is_default() or has_force_limit():
		errors.append("207.5.14 : un Spell de la pile n'a ni filter, ni max_force")
	if row != PieceFilter.RowZone.ANY:
		errors.append("207.5.14 : row ne vaut que pour une case")
	if adjacent_to != AdjacentTo.NONE:
		errors.append("207.5.14 : un Spell de la pile n'a pas de filtre d'adjacence")
	if distinct:
		errors.append("207.5.14 : distinct ne vaut que pour des pièces ou des cases")
