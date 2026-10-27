class_name PieceFilter
extends RefCounted
## Filtre de pièces partagé entre la cible d'un effet (207.5.6) et la portée d'un effet statique
## (206.5.5, 207.2.2, 207.2.8), décision 0062 : côté, genre, relation à une pièce de référence,
## jeton, rangée. L'évaluation est unique, dans `ModifierRules.matches_filter`.
##
## Côté et rangée se lisent par rapport au joueur à qui appartient l'effet ; la relation, par
## rapport à la pièce de référence : la pièce qui porte l'effet (pour un Gear, l'Unit qui le porte,
## 207.2.8) ou le Hero du joueur à qui appartient l'effet (205.2.5).

## Côté de la pièce, relatif au joueur à qui appartient l'effet (glossaire : Allié, Ennemi).
## Enum journalisable : ajouter à la fin.
enum SideFilter {
	ANY,
	ALLY,
	ENEMY,
}

## Position de la pièce par rapport à la pièce de référence. Enum journalisable : ajouter à la fin.
enum Relation {
	ANY,
	SELF,  # la pièce de référence elle-même
	ADJACENT,  # 205.2.5 : une case qui partage un côté avec celle de la référence
	SAME_ROW,  # 201.2.3 : la rangée de la référence
}

## Pièce de référence de la relation. Enum journalisable : ajouter à la fin.
enum RelativeTo {
	SOURCE_PIECE,  # la pièce qui porte l'effet, ou sa dernière case (207.3.14)
	OWN_HERO,  # 205.2.5 : le Hero du joueur à qui appartient l'effet
}

## 202.4.1 : jeton ou non. Enum journalisable : ajouter à la fin.
enum TokenFilter {
	ANY,
	NON_TOKEN,
}

## Zones nommées par 205.1, relatives au joueur à qui appartient l'effet. Enum journalisable :
## ajouter à la fin.
enum RowZone {
	ANY,
	OWN_FIRST,  # 205.1.2 : sa première rangée
	OWN_NEAR,  # 205.1.3 : ses deux rangées les plus proches
	CENTRAL,  # 205.1.4 : la rangée centrale
	NOT_CENTRAL,  # 205.1.4 : hors de la rangée centrale
}

var side: SideFilter = SideFilter.ANY
## Genres admis ; vide : tous.
var piece_kinds: Array[Piece.PieceKind] = []
var relation: Relation = Relation.ANY
var relative_to: RelativeTo = RelativeTo.SOURCE_PIECE
## Faux : « autres », la pièce de référence elle-même est exclue.
var include_reference: bool = true
var tokens: TokenFilter = TokenFilter.ANY
var row: RowZone = RowZone.ANY
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Lit un filtre depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> PieceFilter:
	var filter := PieceFilter.new()
	var reader := CatalogReader.new(data)
	var side_value := reader.read_enum("side", SideFilter)
	if side_value != CatalogReader.NOT_SET:
		filter.side = side_value as SideFilter
	var relation_value := reader.read_enum("relation", Relation)
	if relation_value != CatalogReader.NOT_SET:
		filter.relation = relation_value as Relation
	var relative_value := reader.read_enum("relative_to", RelativeTo)
	if relative_value != CatalogReader.NOT_SET:
		filter.relative_to = relative_value as RelativeTo
	var tokens_value := reader.read_enum("tokens", TokenFilter)
	if tokens_value != CatalogReader.NOT_SET:
		filter.tokens = tokens_value as TokenFilter
	var row_value := reader.read_enum("row", RowZone)
	if row_value != CatalogReader.NOT_SET:
		filter.row = row_value as RowZone
	filter.include_reference = reader.read_bool("include_reference", true)
	filter._read_piece_kinds(reader)
	filter.parse_errors = reader.finish()
	return filter


# 207.5.6, 206.5.5 : chaque champ ne vaut que pour ce qu'il filtre.
func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	if relation == Relation.ANY and not include_reference:
		errors.append("206.5.5 : include_reference faux exige une relation à la référence")
	errors.append_array(_relation_errors())
	return errors


# Décision 0065 : le filtre de l'objet d'un événement peut exclure la pièce de référence sans
# relation (« une autre Unit alliée »).
func find_object_errors() -> PackedStringArray:
	return parse_errors + _relation_errors()


## Vrai si le filtre se lit par rapport à la pièce qui porte l'effet (207.3.14).
func uses_source_piece() -> bool:
	return relation != Relation.ANY and relative_to == RelativeTo.SOURCE_PIECE


## Vrai si aucun champ n'est écrit : le filtre admet toute pièce.
func is_default() -> bool:
	return is_equal_to(PieceFilter.new())


## Vrai si seul le côté est écrit (le Spell contrecarré n'a que son propriétaire, décision 0065).
func is_side_only() -> bool:
	var bare := PieceFilter.new()
	bare.side = side
	return is_equal_to(bare)


## Vrai si les deux filtres ont les mêmes champs.
func is_equal_to(other: PieceFilter) -> bool:
	return (
		side == other.side
		and piece_kinds == other.piece_kinds
		and relation == other.relation
		and relative_to == other.relative_to
		and include_reference == other.include_reference
		and tokens == other.tokens
		and row == other.row
	)


func _relation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if relation == Relation.SELF and not include_reference:
		errors.append("206.5.5 : la relation self exclut la référence, aucune pièce ne convient")
	if relative_to == RelativeTo.OWN_HERO and relation != Relation.ADJACENT:
		errors.append("205.2.5 : own_hero ne sert que la relation adjacent")
	if relative_to != RelativeTo.SOURCE_PIECE and relation == Relation.ANY:
		errors.append("207.5.6 : relative_to exige une relation")
	return errors


func _read_piece_kinds(reader: CatalogReader) -> void:
	for entry: Variant in reader.read_array("piece_kinds"):
		var text: String = entry if typeof(entry) == TYPE_STRING else ""
		var value := CatalogReader.enum_value(Piece.PieceKind, text)
		if value == CatalogReader.NOT_SET:
			reader.fail("« piece_kinds » : %s inconnu" % str(entry))
		else:
			piece_kinds.append(value as Piece.PieceKind)
