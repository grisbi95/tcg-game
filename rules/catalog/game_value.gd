class_name GameValue
extends RefCounted
## Valeur du jeu (décision 0065) : vocabulaire fermé lu par une condition « si » (207.3.13, 207.7.1)
## et par un champ « X » d'un effet (213.1.8, 213.2.1). La lecture est unique, dans
## `ValueRules.read_value` ; les moments où une valeur a un sens sont contrôlés par
## `EffectValueChecks`.

## Enum journalisable : ajouter à la fin, sans réordonner.
enum Kind {
	HAND_SIZE,  # cartes en main du joueur à qui appartient l'effet
	PIECE_COUNT,  # pièces en jeu qui remplissent `piece_filter` (décision 0062)
	SOURCE_FORCE,  # Force actuelle de la pièce qui porte l'effet (213.2.3, 213.2.4)
	TARGET_FORCE,  # Force actuelle de l'unique Unit ciblée (213.2.3, 213.2.4)
	DISCARDED_BY_PREVIOUS_EFFECT,  # cartes défaussées par l'effet précédent du même texte
	CHOSEN_X,  # 213.1.3 : la valeur choisie à l'annonce du Spell à coût X
	EVENT_SPELL_COST,  # coût actuel, X compris, du Spell de l'événement (213.1.6)
}

var kind: Kind = Kind.HAND_SIZE
## Pour PIECE_COUNT seulement ; null sinon.
var piece_filter: PieceFilter
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Lit une valeur depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> GameValue:
	var value := GameValue.new()
	var reader := CatalogReader.new(data)
	reader.require("kind", "0065")
	var kind_value := reader.read_enum("kind", Kind)
	if kind_value != CatalogReader.NOT_SET:
		value.kind = kind_value as Kind
	if reader.has("filter"):
		value.piece_filter = PieceFilter.from_dict(reader.read_object("filter"))
	value.parse_errors = reader.finish()
	return value


## Vrai si la valeur compte des pièces par rapport à la pièce qui porte l'effet (207.3.14).
func uses_source_piece() -> bool:
	return piece_filter != null and piece_filter.uses_source_piece()


func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	if kind == Kind.PIECE_COUNT and piece_filter == null:
		errors.append("0065 : piece_count nomme les pièces comptées dans filter")
	if kind != Kind.PIECE_COUNT and piece_filter != null:
		errors.append("0065 : filter ne vaut que pour piece_count")
	if piece_filter != null:
		for message: String in piece_filter.find_errors():
			errors.append("filter : " + message)
	return errors
