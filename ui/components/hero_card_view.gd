class_name HeroCardView
extends Control
## Carte Hero d'un joueur (202.3 ; décision 0032) : une CardView de 158×220 entourée du liseré
## épais de la couleur fixe de son joueur, qui laisse voir sa teinte. Elle n'est pas cliquable :
## le Hero n'a plus de pouvoir (décision 0208). Un texte long réduit sa taille de police dans la
## CardView, qui garde ses 158×220. Les PV montrés sont les PV imprimés ; les PV en jeu sont sur
## la pièce du plateau. Le survol est relayé pour l'aperçu.

signal hero_card_hovered
signal hero_card_unhovered

var _player: DuelState.PlayerSide = DuelState.PlayerSide.A
var _marks := ControlMarks.new(self, DuelMarks.RING_WIDTH + DuelMarks.RING_GAP)

@onready var _card: CardView = %Card
@onready var _frame: Control = %Frame


func _ready() -> void:
	custom_minimum_size = CardView.CARD_SIZE
	_marks.hover_changed.connect(_on_hover_changed)
	_frame.draw.connect(_draw_frame)


func _draw() -> void:
	_marks.draw()


## Carte du Hero `hero` du joueur `player`, liseré de sa couleur.
func setup(player: DuelState.PlayerSide, hero: HeroDefinition) -> void:
	_player = player
	_card.show_hero(hero)
	_frame.queue_redraw()


func _draw_frame() -> void:
	var frame := DuelPalette.framed_style(
		Color.TRANSPARENT, DuelPalette.player_color(_player), DuelPalette.PLAYER_BORDER_WIDTH, 0.0
	)
	frame.draw_center = false
	_frame.draw_style_box(frame, Rect2(Vector2.ZERO, _frame.size))


func _on_hover_changed(is_hovered: bool) -> void:
	if is_hovered:
		hero_card_hovered.emit()
	else:
		hero_card_unhovered.emit()
