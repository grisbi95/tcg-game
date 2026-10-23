class_name DuelPreviewer
extends RefCounted
## Aperçu au survol pour l'écran de duel (décisions 0027 et 0030) : traduit un survol en carte,
## Hero, jeton ou entrée de pile à montrer dans `HoverPreview`, d'après ce que voit le joueur qui a
## l'appareil (`DuelViewModel`). Aucune règle ici.

var _preview: HoverPreview
var _engine: DuelEngine
var _model: DuelViewModel


## `preview` est la vue qui montre l'aperçu ; `engine`, le moteur du duel (Force actuelle).
func setup(preview: HoverPreview, engine: DuelEngine) -> void:
	_preview = preview
	_engine = engine


## Ce que voit le joueur qui a l'appareil, à redonner après chaque recalage.
func use_model(model: DuelViewModel) -> void:
	_model = model


func show_card(card_instance_id: int) -> void:
	var definition := _model.visible_definition(card_instance_id)
	if definition != null:
		_preview.show_card(definition)


func show_hero(side: DuelState.PlayerSide) -> void:
	_preview.show_hero(_model.hero_definition(side))


func show_piece(piece_id: int) -> void:
	var piece := _engine.get_state().find_piece(piece_id)
	if piece == null:
		return
	var gear := _model.gear_definition(piece)
	match DuelViewModel.piece_form_of(piece):
		DuelViewModel.PieceForm.HERO:
			_preview.show_hero(_model.hero_definition(piece.owner), gear)
		DuelViewModel.PieceForm.TOKEN:
			var force := _engine.current_force(piece_id)
			_preview.show_token(_model.token_card_type(piece), force, gear)
		DuelViewModel.PieceForm.CARD:
			_preview.show_card(_model.piece_definition(piece), gear)


func show_stack_entry(stack_entry_id: int) -> void:
	var entry := _model.find_entry(stack_entry_id)
	if entry == null:
		return
	var definition := _model.entry_definition(entry)
	if definition != null:
		_preview.show_card(definition)


func hide_preview(_ignored_id: int = DuelState.NO_ID) -> void:
	_preview.hide_preview()
