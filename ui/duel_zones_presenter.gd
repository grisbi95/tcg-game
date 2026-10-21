class_name DuelZonesPresenter
extends RefCounted
## Recalage des zones de l'écran de duel sur l'état du moteur (décisions 0030 et 0032) : pièces du
## plateau, deck et Écart, Sources et cartes Hero. Reçoit à chaque appel le `DuelViewModel` du
## joueur qui a l'appareil ; aucune règle ici.

const PIECE_SCENE: PackedScene = preload("res://ui/components/piece_view.tscn")

var _board: BoardView
var _engine: DuelEngine
var _on_piece_hovered: Callable
var _on_piece_unhovered: Callable
var _piece_views: Dictionary[int, PieceView] = {}
var _sources: Dictionary[DuelState.PlayerSide, SourcesView] = {}
var _deck_corners: Dictionary[DuelState.PlayerSide, DeckCornerView] = {}
var _hero_cards: Dictionary[DuelState.PlayerSide, HeroCardView] = {}


## `board` reçoit les pièces ; `engine` donne l'état et la Force actuelle ; le survol d'une pièce
## appelle `on_piece_hovered(piece_id)`, et sa fin `on_piece_unhovered`.
func setup(
	board: BoardView, engine: DuelEngine, on_piece_hovered: Callable, on_piece_unhovered: Callable
) -> void:
	_board = board
	_engine = engine
	_on_piece_hovered = on_piece_hovered
	_on_piece_unhovered = on_piece_unhovered


## Les vues d'un joueur, à donner pour A et pour B.
func add_player_zones(
	side: DuelState.PlayerSide,
	sources: SourcesView,
	deck_corner: DeckCornerView,
	hero_card: HeroCardView
) -> void:
	_sources[side] = sources
	_deck_corners[side] = deck_corner
	_hero_cards[side] = hero_card


## Marques des pièces : légales à choisir, et choisie.
func show_piece_marks(shown: SelectionSnapshot) -> void:
	for piece_id: int in _piece_views:
		_piece_views[piece_id].set_marks(
			shown.legal_piece_ids.has(piece_id), shown.chosen_piece_id == piece_id
		)


## Reconstruit les pièces du plateau d'après l'état, vues par `model`.
func refresh_pieces(model: DuelViewModel) -> void:
	_board.clear_pieces()
	_piece_views.clear()
	for piece: Piece in _engine.get_state().pieces:
		var piece_view: PieceView = PIECE_SCENE.instantiate()
		_board.put_piece(piece.cell, piece_view)
		_fill_piece(piece_view, piece, model)
		piece_view.piece_hovered.connect(_on_piece_hovered)
		piece_view.piece_unhovered.connect(_on_piece_unhovered)
		_piece_views[piece.piece_id] = piece_view


## Deck, fatigue et sommet de l'Écart de chaque joueur.
func refresh_piles(model: DuelViewModel) -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var corner := _deck_corners[side]
		corner.show_deck(model.deck_size(side))
		corner.show_fatigue(model.fatigue(side))
		var top := model.discard_top(side)
		if top == null:
			corner.show_empty_discard()
		else:
			corner.show_discard(top.card_instance_id, top.definition)


## Sources, réserve, Essence affichée ; seules celles du joueur de l'appareil se pressent.
func refresh_sources(model: DuelViewModel, shown: SelectionSnapshot) -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var view := _sources[side]
		var player := _engine.get_state().get_player(side)
		view.show_sources(model.upright_sources(side, shown), model.tilted_sources(side, shown))
		view.show_supply(player.sources_in_reserve, player.sources_in_fonte)
		view.show_essence(model.essence_shown(side, shown))
		view.set_interactive(side == model.get_viewer())


## Décision 0032, point 3 : seul le joueur qui a l'appareil clique sa carte Hero.
func refresh_hero_cards(model: DuelViewModel, shown: SelectionSnapshot) -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var is_viewer := side == model.get_viewer()
		_hero_cards[side].set_clickable(is_viewer)
		_hero_cards[side].set_power_usable(is_viewer and shown.can_use_hero_power)
		_hero_cards[side].set_power_chosen(is_viewer and shown.is_hero_power_chosen)


# La pièce est posée sur sa case avant d'être remplie : ses nœuds n'existent qu'une fois en scène.
func _fill_piece(piece_view: PieceView, piece: Piece, model: DuelViewModel) -> void:
	var gear := model.gear_definition(piece)
	piece_view.show_gear("" if gear == null else gear.card_name)
	var force := _engine.current_force(piece.piece_id)
	match DuelViewModel.piece_form_of(piece):
		DuelViewModel.PieceForm.HERO:
			var hero := model.hero_definition(piece.owner)
			piece_view.show_hero(piece.piece_id, hero, piece.owner)
			piece_view.show_health(piece.health)
		DuelViewModel.PieceForm.TOKEN:
			var card_type := model.token_card_type(piece)
			piece_view.show_token(piece.piece_id, card_type, piece.owner)
			piece_view.show_force(force, piece.token_force)
		DuelViewModel.PieceForm.CARD:
			var definition := model.piece_definition(piece)
			piece_view.show_card_piece(piece.piece_id, definition, piece.owner)
			piece_view.show_force(force, definition.force)
