class_name TrySamples
extends RefCounted
## Données des scènes d'essai (ui/CLAUDE.md) : les cartes et le Hero des decks de test, et le
## cadre commun qui centre le composant essayé.

const CARDS_DIRECTORY: String = "res://data/cards"
const HERO_ID: StringName = &"capitaine"
const MARGIN: int = 40


static func catalog() -> Catalog:
	var loader := CatalogLoader.new()
	loader.load_directory(CARDS_DIRECTORY)
	for error: String in loader.find_errors():
		push_error("TrySamples : " + error)
	return loader.get_catalog()


## 201.2.4 : cases dans l'ordre d'une grille, la rangée 1 (celle de A) en bas, les colonnes de
## A à E de gauche à droite.
static func cells_in_display_order() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row: int in range(BoardGeometry.ROW_COUNT - 1, -1, -1):
		for column: int in BoardGeometry.COLUMN_COUNT:
			cells.append(Vector2i(column, row))
	return cells


## Ajoute à `root` une marge et le conteneur `content`, en haut, à la hauteur de ses composants.
static func frame(root: Control, content: Container) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, MARGIN)
	root.add_child(margin)
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	margin.add_child(content)
