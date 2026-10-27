class_name PlaytestSuite
extends GdUnitTestSuite
## Socle des suites du catalogue de playtest (ruleset 0.55, docs/ruleset/50-cartes/, étape c.6) :
## charge data/cards/ une fois et fournit les contrôles de forme d'une carte.

const EDITION: String = "0.55"  # docs/ruleset/README.md, édition courante
const TYPE := CardDefinition.CardType
const SPEED := CardDefinition.SpellSpeed
const KEYWORD := CardDefinition.Keyword
const KIND := EffectDefinition.EffectKind
const TRIGGER := EffectDefinition.TriggerEvent
const SIDE := PieceFilter.SideFilter
const RELATION := PieceFilter.Relation
const DURATION := ActiveEffect.EffectDuration

var _catalog: Catalog
var _loader: CatalogLoader


func before() -> void:
	_loader = CatalogLoader.new(EDITION)
	_loader.load_directory(GameLibrary.CARDS_DIRECTORY)
	_catalog = _loader.get_catalog()


func _effects(card_id: StringName) -> Array[EffectDefinition]:
	return EffectText.all_effects(_catalog.get_card(card_id).texts)


func _assert_card(card_id: StringName, shape: Array, keywords: Dictionary, kinds: Array) -> void:
	var card := _catalog.get_card(card_id)
	assert_object(card).override_failure_message(String(card_id)).is_not_null()
	var actual: Array = [card.card_type, card.cost, card.force, card.speed]
	assert_array(actual).override_failure_message(String(card_id)).is_equal(shape)
	assert_dict(card.keywords).override_failure_message(String(card_id)).is_equal(keywords)
	var actual_kinds: Array = _effects(card_id).map(
		func(effect: EffectDefinition) -> int: return effect.kind
	)
	assert_array(actual_kinds).override_failure_message(String(card_id)).is_equal(kinds)
	assert_array(Array(card.find_errors())).override_failure_message(String(card_id)).is_empty()


func _assert_trigger(card_id: StringName, trigger: EffectDefinition.TriggerEvent) -> void:
	var texts := _catalog.get_card(card_id).texts
	assert_int(texts.size()).is_equal(1)
	assert_int(texts[0].timing).is_equal(EffectDefinition.EffectTiming.TRIGGERED)
	assert_int(texts[0].trigger).is_equal(trigger)


func _assert_once_per_turn(card_id: StringName) -> void:
	assert_bool(_catalog.get_card(card_id).texts[0].once_per_turn).is_true()


func _assert_not_once_per_turn(card_id: StringName) -> void:
	assert_bool(_catalog.get_card(card_id).texts[0].once_per_turn).is_false()


func _assert_source_subject(card_id: StringName) -> void:
	for effect: EffectDefinition in _effects(card_id):
		assert_int(effect.subject).is_equal(EffectDefinition.EffectSubject.SOURCE_PIECE)
		assert_object(effect.target).is_null()


func _assert_amount(card_id: StringName, amount: int) -> void:
	assert_int(_effects(card_id)[0].amount).is_equal(amount)


## Cible d'un effet : côté, et Force maximale si `max_force` est donnée.
func _assert_target(
	card_id: StringName, side: PieceFilter.SideFilter, max_force: int = TargetSpec.NO_FORCE_LIMIT
) -> void:
	var target := _effects(card_id)[0].target
	assert_object(target).is_not_null()
	assert_int(target.piece_filter.side).is_equal(side)
	assert_int(target.max_force).is_equal(max_force)


func _assert_static_scope(
	card_id: StringName, side: PieceFilter.SideFilter, relation: PieceFilter.Relation
) -> void:
	var texts := _catalog.get_card(card_id).texts
	assert_int(texts.size()).is_equal(1)
	assert_int(texts[0].timing).is_equal(EffectDefinition.EffectTiming.STATIC)
	var scope := texts[0].effects[0].scope
	assert_int(scope.side).is_equal(side)
	assert_int(scope.relation).is_equal(relation)


func _assert_others_only(card_id: StringName) -> void:
	assert_bool(_effects(card_id)[0].scope.include_reference).is_false()


func _assert_token(card_id: StringName, token_force: int) -> void:
	var effect := _effects(card_id)[0]
	assert_int(effect.token_piece_kind).is_equal(Piece.PieceKind.UNIT)
	assert_int(effect.token_force).is_equal(token_force)
	assert_int(effect.target.what).is_equal(TargetSpec.TargetWhat.CELL)


func _assert_two_distinct_targets(card_id: StringName) -> void:
	var target := _effects(card_id)[0].target
	assert_bool(target.distinct).is_true()
	assert_int(target.count_min).is_equal(2)
	assert_int(target.count_max).is_equal(2)


func _assert_destination(card_id: StringName) -> void:
	var destination := _effects(card_id)[0].destination
	assert_int(destination.what).is_equal(TargetSpec.TargetWhat.CELL)
	assert_int(destination.adjacent_to).is_equal(TargetSpec.AdjacentTo.TARGET_PIECE)


func _assert_adjacent_to_source(card_id: StringName) -> void:
	var filter := _effects(card_id)[0].target.piece_filter
	assert_int(filter.relation).is_equal(RELATION.ADJACENT)
	assert_int(filter.relative_to).is_equal(PieceFilter.RelativeTo.SOURCE_PIECE)


func _assert_source_destroy_last(card_id: StringName) -> void:
	var effects := _effects(card_id)
	assert_int(effects[1].subject).is_equal(EffectDefinition.EffectSubject.SOURCE_PIECE)
	assert_bool(effects[1].if_you_do).is_false()


## X Force de la cible à la résolution : mot-clé `keyword` jusqu'à la fin du tour.
func _assert_force_keyword(card_id: StringName, keyword: CardDefinition.Keyword) -> void:
	var effect := _effects(card_id)[0]
	assert_int(effect.keyword).is_equal(keyword)
	assert_bool(effect.amount_is_x).is_true()
	assert_int(effect.x_from.kind).is_equal(GameValue.Kind.TARGET_FORCE)
	assert_int(effect.duration).is_equal(DURATION.UNTIL_END_OF_TURN)
	assert_int(effect.target.piece_filter.side).is_equal(SIDE.ALLY)


## Piocher puis défausser, dans l'ordre du texte (207.7.4), sans dépendance entre les effets.
func _assert_study_order(card_id: StringName, drawn: int = 2) -> void:
	var effects := _effects(card_id)
	assert_int(effects[0].amount).is_equal(drawn)
	assert_int(effects[1].amount).is_equal(1)
	assert_bool(effects[1].if_you_do).is_false()


func _assert_execution(card_id: StringName) -> void:
	var effect := _effects(card_id)[0]
	assert_bool(effect.target.max_force_is_x).is_true()
	assert_int(effect.x_from.kind).is_equal(GameValue.Kind.CHOSEN_X)
	assert_int(effect.target.piece_filter.side).is_equal(SIDE.ENEMY)
