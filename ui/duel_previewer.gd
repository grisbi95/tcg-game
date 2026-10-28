class_name DuelPreviewer
extends RefCounted
## Aperçu au survol pour l'écran de duel (décisions 0027 et 0030) : traduit un survol en carte,
## Hero, jeton ou entrée de pile à montrer dans `HoverPreview`, d'après ce que voit le joueur qui a
## l'appareil (`DuelViewModel`). Aucune règle ici.

var _preview: HoverPreview
var _tooltips: InfoTooltips
var _engine: DuelEngine
var _model: DuelViewModel


## `preview` est la vue qui montre l'aperçu ; `engine`, le moteur du duel (Force actuelle) ;
## `tooltips`, les bulles d'information qui l'accompagnent (null : sans bulles).
func setup(preview: HoverPreview, engine: DuelEngine, tooltips: InfoTooltips = null) -> void:
	_preview = preview
	_engine = engine
	_tooltips = tooltips


## Ce que voit le joueur qui a l'appareil, à redonner après chaque recalage.
func use_model(model: DuelViewModel) -> void:
	_model = model


func show_card(card_instance_id: int) -> void:
	var definition := _model.visible_definition(card_instance_id)
	if definition != null:
		_preview.show_card(definition)
		_show_bubbles(definition, null, false)


func show_piece(piece_id: int) -> void:
	var piece := _engine.get_state().find_piece(piece_id)
	if piece == null:
		return
	var gear := _model.gear_definition(piece)
	var definition: CardDefinition = null
	match DuelViewModel.piece_form_of(piece):
		DuelViewModel.PieceForm.HERO:
			_preview.show_hero(_model.hero_definition(piece.owner), gear)
		DuelViewModel.PieceForm.TOKEN:
			var force := _engine.current_force(piece_id)
			_preview.show_token(DuelViewModel.token_card_type(piece), force, gear)
		DuelViewModel.PieceForm.CARD:
			definition = _model.piece_definition(piece)
			_preview.show_card(definition, gear)
	_show_bubbles(definition, gear, DuelViewModel.is_shown_asleep(piece))


func show_stack_entry(stack_entry_id: int) -> void:
	var entry := _model.find_entry(stack_entry_id)
	if entry == null:
		return
	if entry.kind == StackEntry.StackEntryKind.ORDER:
		_preview.show_hero(_model.hero_definition(entry.owner), null)
		_show_bubbles(null, null, false)
		return
	var definition := _model.entry_definition(entry)
	if definition != null:
		_preview.show_card(definition)
		_show_bubbles(definition, null, false)


func hide_preview(_ignored_id: int = DuelState.NO_ID) -> void:
	_preview.hide_preview()
	if _tooltips != null:
		_tooltips.hide_bubbles()


func _show_bubbles(definition: CardDefinition, gear: CardDefinition, is_asleep: bool) -> void:
	if _tooltips != null:
		_tooltips.show_bubbles(InfoBubble.list_for(definition, gear, is_asleep), gear != null)
