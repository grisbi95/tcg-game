extends Control
## Essai de DeckCornerView (décisions 0030 et 0032) : le coin de A (16 cartes, défausse dont le
## dessus est « Contre », libellé au-dessus), celui de B (19 cartes, défausse vide, libellé
## dessous) et un coin à deck vide et fatigue 2. Le survol de la défausse s'écrit dans la sortie.

const CORNER_SCENE: PackedScene = preload("res://ui/components/deck_corner_view.tscn")
const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const CORNER_GAP: int = 60
const A_DECK_COUNT: int = 16
const B_DECK_COUNT: int = 19
const EMPTY_DECK_FATIGUE: int = 2
const A_DISCARD_ID: int = 31
const EMPTY_DECK_DISCARD_ID: int = 32


func _ready() -> void:
	var catalog := TrySamples.catalog()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", CORNER_GAP)
	TrySamples.frame(self, row)
	var corner_a := _add_corner(row, A, DeckCornerView.LabelPlacement.ABOVE)
	corner_a.show_deck(A_DECK_COUNT)
	corner_a.show_discard(A_DISCARD_ID, catalog.get_card(&"contre"))
	var corner_b := _add_corner(row, B, DeckCornerView.LabelPlacement.BELOW)
	corner_b.show_deck(B_DECK_COUNT)
	var corner_empty := _add_corner(row, A, DeckCornerView.LabelPlacement.ABOVE)
	corner_empty.show_deck(0)
	corner_empty.show_fatigue(EMPTY_DECK_FATIGUE)
	corner_empty.show_discard(EMPTY_DECK_DISCARD_ID, catalog.get_card(&"frappe"))


func _add_corner(
	row: HBoxContainer, player: DuelState.PlayerSide, label_placement: DeckCornerView.LabelPlacement
) -> DeckCornerView:
	var corner: DeckCornerView = CORNER_SCENE.instantiate()
	row.add_child(corner)
	corner.setup(player, label_placement)
	corner.discard_hovered.connect(
		func(id: int) -> void: print("survol de la défausse, carte ", id)
	)
	corner.discard_unhovered.connect(
		func(id: int) -> void: print("fin de survol de la défausse, carte ", id)
	)
	return corner
