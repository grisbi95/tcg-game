class_name TargetSpec
extends RefCounted
## Cible que choisit un effet (207.5, décisions 0002 et 0010) : ce qui se vise et les filtres.
##
## Un effet statique ne cible pas (207.2.1, 207.5.1) : il a une portée, voir StaticScope. La
## validité à l'ajout à la pile et à la résolution est jugée par le module du chapitre 207.

## 207.5.11, 207.5.14 : ce qu'un effet peut cibler. Enum journalisable : ajouter à la fin.
enum TargetWhat {
	PIECE,  # 207.5.11 : Hero, jeton compris (207.5.11a, 207.5.11b)
	CELL,  # 207.5.11, 202.4.12
	SPELL_ON_STACK,  # 207.5.14
}

## Côté de la pièce visée, relatif au joueur à qui appartient l'effet (glossaire : Allié, Ennemi).
enum TargetSide {
	ANY,
	ALLY,
	ENEMY,
}

## Rangée admise pour une case ciblée, relative au joueur à qui appartient l'effet.
enum CellRow {
	ANY,
	OWN_FIRST,  # 205.1.3 : sa première rangée
}

## Filtre d'adjacence de la cible (décision 0056). Enum journalisable : ajouter à la fin.
enum AdjacentTo {
	NONE,
	TARGET_PIECE,  # case adjacente à la pièce que cible le même effet (destination, 215.1.1)
	OWN_HERO,  # pièce adjacente au Hero du joueur à qui appartient l'effet (205.2.5)
	SOURCE_PIECE,  # adjacente à la case de la pièce qui porte l'effet, ou à sa dernière (207.3.14)
}

## Valeur de `max_force` quand la Force de la cible n'est pas bornée.
const NO_FORCE_LIMIT: int = -1
const MIN_TARGET_COUNT: int = 1  # 207.5.10

var what: TargetWhat = TargetWhat.PIECE
var side: TargetSide = TargetSide.ANY
var piece_kinds: Array[Piece.PieceKind] = []
## Borne haute de la Force actuelle de la cible (« de Force 3 ou moins »).
var max_force: int = NO_FORCE_LIMIT
## Décision 0058, 213.1.10 : `max_force` s'écrit « X » ; la valeur vient de `x_source` de l'effet,
## et `with_x()` en fait une borne chiffrée.
var max_force_is_x: bool = false
var row: CellRow = CellRow.ANY
var adjacent_to: AdjacentTo = AdjacentTo.NONE
var count_min: int = MIN_TARGET_COUNT
var count_max: int = MIN_TARGET_COUNT
## 207.3.14 : case de la pièce source pour `AdjacentTo.SOURCE_PIECE` (`with_source_cell`), lue à
## l'exécution, jamais du JSON.
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
	var side_value := reader.read_enum("side", TargetSide)
	if side_value != CatalogReader.NOT_SET:
		spec.side = side_value as TargetSide
	var row_value := reader.read_enum("row", CellRow)
	if row_value != CatalogReader.NOT_SET:
		spec.row = row_value as CellRow
	var adjacent_value := reader.read_enum("adjacent_to", AdjacentTo)
	if adjacent_value != CatalogReader.NOT_SET:
		spec.adjacent_to = adjacent_value as AdjacentTo
	spec._read_piece_kinds(reader)
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
	match what:
		TargetWhat.PIECE:
			_check_piece(errors)
		TargetWhat.CELL:
			_check_cell(errors)
		TargetWhat.SPELL_ON_STACK:
			_check_spell_on_stack(errors)
	if count_min < MIN_TARGET_COUNT or count_max < count_min:
		errors.append("207.5.10 : count_min au moins 1 et count_max au moins count_min")
	return errors


## 213.1.10, 213.1.11 : cette cible où « X » vaut `x_value` ; `self` si elle n'a pas de X.
func with_x(x_value: int) -> TargetSpec:
	if not max_force_is_x:
		return self
	var copy := _copy()
	copy.max_force = x_value
	copy.max_force_is_x = false
	return copy


## 207.3.14 : cette cible où `AdjacentTo.SOURCE_PIECE` se lit par rapport à `cell` ; `self` sinon.
func with_source_cell(cell: Vector2i) -> TargetSpec:
	if adjacent_to != AdjacentTo.SOURCE_PIECE:
		return self
	var copy := _copy()
	copy.source_cell = cell
	return copy


## Vrai si la Force de la cible est bornée, par un nombre ou par X.
func has_force_limit() -> bool:
	return max_force != NO_FORCE_LIMIT or max_force_is_x


func _copy() -> TargetSpec:
	var copy := TargetSpec.new()
	copy.what = what
	copy.side = side
	copy.piece_kinds.assign(piece_kinds)
	copy.max_force = max_force
	copy.max_force_is_x = max_force_is_x
	copy.row = row
	copy.adjacent_to = adjacent_to
	copy.count_min = count_min
	copy.count_max = count_max
	copy.source_cell = source_cell
	copy.parse_errors = parse_errors.duplicate()
	return copy


func _read_piece_kinds(reader: CatalogReader) -> void:
	for entry: Variant in reader.read_array("piece_kinds"):
		var text: String = entry if typeof(entry) == TYPE_STRING else ""
		var value := CatalogReader.enum_value(Piece.PieceKind, text)
		if value == CatalogReader.NOT_SET:
			reader.fail("« piece_kinds » : %s inconnu" % str(entry))
		else:
			piece_kinds.append(value as Piece.PieceKind)


func _check_piece(errors: PackedStringArray) -> void:
	if piece_kinds.is_empty():
		errors.append("207.5.11 : une cible pièce nomme au moins un genre dans piece_kinds")
	if row != CellRow.ANY:
		errors.append("207.5.11 : row ne vaut que pour une case")
	if max_force < NO_FORCE_LIMIT:
		errors.append("207.5.11 : max_force est au moins 0")
	if has_force_limit() and piece_kinds.has(Piece.PieceKind.HERO):
		errors.append("202.3.9 : un Hero n'a pas de Force, max_force l'exclut des genres")
	if adjacent_to == AdjacentTo.TARGET_PIECE:
		errors.append("215.1.1 : target_piece ne vaut que pour une case de destination")


func _check_cell(errors: PackedStringArray) -> void:
	if side != TargetSide.ANY or not piece_kinds.is_empty() or has_force_limit():
		errors.append("207.5.11 : une case n'a ni side, ni piece_kinds, ni max_force")
	if adjacent_to == AdjacentTo.OWN_HERO:
		errors.append("207.5.11 : own_hero ne vaut que pour une pièce")


func _check_spell_on_stack(errors: PackedStringArray) -> void:
	if side != TargetSide.ANY or not piece_kinds.is_empty() or has_force_limit():
		errors.append("207.5.14 : un Spell de la pile n'a ni side, ni piece_kinds, ni max_force")
	if row != CellRow.ANY:
		errors.append("207.5.14 : row ne vaut que pour une case")
	if adjacent_to != AdjacentTo.NONE:
		errors.append("207.5.14 : un Spell de la pile n'a pas de filtre d'adjacence")
