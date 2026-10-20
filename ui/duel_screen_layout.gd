class_name DuelScreenLayout
extends RefCounted
## Cotes de l'écran de duel (décision 0030), en pixels du repère 1920×1080, marges de 16 px, et
## ancrage d'une zone à ces cotes.

const VIEWPORT_SIZE := Vector2(1920.0, 1080.0)
const MARGIN: float = 16.0
const TOP_LEFT_CORNER := Vector2(MARGIN, MARGIN)
const TOP_RIGHT_CORNER := Vector2(VIEWPORT_SIZE.x - MARGIN, MARGIN)
const BOTTOM_LEFT_CORNER := Vector2(MARGIN, VIEWPORT_SIZE.y - MARGIN)
const BOTTOM_RIGHT_CORNER := Vector2(VIEWPORT_SIZE.x - MARGIN, VIEWPORT_SIZE.y - MARGIN)
## Décision 0035 (modifie la cote y 94 de 0030) : haut de la grille du plateau et de la colonne de
## duel, remonté de 6 px pour que les repères A-E ne mordent pas sur la main.
const GRID_TOP: float = 88.0
## Plateau : coin haut-gauche de sa grille (x 595), qu'il déborde de `BoardView.GRID_OFFSET`
## pour les repères de colonnes et de rangées.
const BOARD_POSITION := Vector2(595.0, GRID_TOP) - BoardView.GRID_OFFSET
## Colonne de duel, collée à droite du plateau, alignée sur la grille.
const COLUMN_POSITION := Vector2(1342.0, GRID_TOP)
## Main du bas : coin haut-gauche (x 424, y 844), donc bord bas à 844 + 220.
const HAND_BOTTOM_LEFT := Vector2(424.0, 844.0 + CardView.CARD_SIZE.y)
## Main adverse : centrée en haut.
const OPPONENT_HAND_POSITION := Vector2(VIEWPORT_SIZE.x / 2.0, MARGIN)
## Centre de l'aperçu, dans la colonne gauche entre les compteurs des deux joueurs.
const PREVIEW_CENTER := Vector2(294.0, 543.0)


## Ancre `control` à `preset` et place à `position` (repère 1920×1080) le point de la zone qui est
## du côté de son ancre : bord droit ou bas pour un ancrage à droite ou en bas, coin haut-gauche
## sinon. La zone prend sa taille minimale et grandit à l'opposé de son ancre, ce qui la garde
## collée à son coin quand l'écran change de proportion.
static func pin(control: Control, preset: Control.LayoutPreset, position: Vector2) -> void:
	control.set_anchors_preset(preset)
	var anchor := Vector2(control.anchor_left, control.anchor_top)
	var offset := position - anchor * VIEWPORT_SIZE
	control.offset_left = offset.x
	control.offset_right = offset.x
	control.offset_top = offset.y
	control.offset_bottom = offset.y
	control.grow_horizontal = (
		Control.GROW_DIRECTION_BEGIN if anchor.x >= 1.0 else Control.GROW_DIRECTION_END
	)
	control.grow_vertical = (
		Control.GROW_DIRECTION_BEGIN if anchor.y >= 1.0 else Control.GROW_DIRECTION_END
	)
