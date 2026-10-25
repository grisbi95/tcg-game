class_name ColumnLettersView
extends HBoxContainer
## Repères « A » à « E » des colonnes du plateau (201.2 ; fiche E05), sous la barre de temps du bas.
## Cinq libellés de même largeur séparés de `BoardView.CELL_GAP` tombent sous les cinq colonnes
## d'une grille de la même largeur. Décision 0050 : vu du joueur B, l'ordre est inversé comme celui
## des colonnes du plateau.

const LETTER_HEIGHT: float = 20.0
const LETTER_LOOK: StringName = &"BoardCoordinateLabel"


func _ready() -> void:
	show_from_side(DuelState.PlayerSide.A)


## Écrit les lettres dans l'ordre des colonnes vues du joueur `bottom_side`.
func show_from_side(bottom_side: DuelState.PlayerSide) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var column_indexes := range(BoardGeometry.COLUMN_COUNT)
	if bottom_side != DuelState.PlayerSide.A:
		column_indexes.reverse()
	for column: int in column_indexes:
		add_child(_make_letter(BoardGeometry.cell_name(Vector2i(column, 0)).left(1)))


## Libellé centré d'un repère du plateau (lettre de colonne ou numéro de rangée).
static func make_coordinate_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = LETTER_LOOK
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _make_letter(text: String) -> Label:
	var label := make_coordinate_label(text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.y = LETTER_HEIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
