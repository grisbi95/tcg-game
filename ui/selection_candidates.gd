class_name SelectionCandidates
extends RefCounted
## Intentions candidates d'un joueur à l'écran (décision 0024) : fabriquées à partir de l'état en
## lecture, avec un paiement donné, et gardées seulement si DuelEngine.validate() les accepte.
## Aucune règle ici. Un objet sert pour une question, le paiement ne changeant pas entre-temps.

var _engine: DuelEngine
var _side: DuelState.PlayerSide = DuelState.PlayerSide.A
var _payment: EssencePayment = EssencePayment.new()


func _init(engine: DuelEngine, side: DuelState.PlayerSide, payment: EssencePayment) -> void:
	_engine = engine
	_side = side
	_payment = payment


func is_legal(intent: DuelIntent) -> bool:
	return _engine.validate(intent) == IntentRejected.RejectReason.NONE


## Annonce de la carte `card_id`, un Spell ou un Gear, avec `target`.
func card_announcement(card_id: int, target: SelectionTarget) -> DuelIntent:
	if _card_type(card_id) == CardDefinition.CardType.GEAR:
		var unit_id: int = DuelState.NO_ID
		if not target.piece_ids.is_empty():
			unit_id = target.piece_ids[0]
		return AttachGear.new(_side, card_id, unit_id, _copy_payment())
	var cast := CastSpell.new(_side, card_id, _copy_payment())
	target.assign_to(cast)
	return cast


func hero_power_announcement(target: SelectionTarget) -> UseHeroPower:
	var power := UseHeroPower.new(_side, _copy_payment())
	target.assign_to(power)
	return power


## Réponse à l'attente CHOOSE_TARGETS, avec `target`.
func targets_answer(target: SelectionTarget) -> ChooseTargets:
	var answer := ChooseTargets.new(_side)
	target.assign_to(answer)
	return answer


func deploy(card_id: int, cell: Vector2i) -> DeployCard:
	return DeployCard.new(_side, card_id, cell, _copy_payment())


func normal_action(piece_id: int, cell: Vector2i) -> TakeNormalAction:
	return TakeNormalAction.new(_side, piece_id, cell)


func card_targets(card_id: int) -> Array[SelectionTarget]:
	return _legal_targets(
		func(target: SelectionTarget) -> DuelIntent: return card_announcement(card_id, target)
	)


func hero_power_targets() -> Array[SelectionTarget]:
	return _legal_targets(hero_power_announcement)


func decision_targets() -> Array[SelectionTarget]:
	return _legal_targets(targets_answer)


func deploy_cells(card_id: int) -> Array[Vector2i]:
	return BoardGeometry.all_cells().filter(
		func(cell: Vector2i) -> bool: return is_legal(deploy(card_id, cell))
	)


func move_cells(piece_id: int) -> Array[Vector2i]:
	return BoardGeometry.all_cells().filter(
		func(cell: Vector2i) -> bool: return is_legal(normal_action(piece_id, cell))
	)


## L'annonce de `card_id` est légale sans cible ou avec une cible.
func is_card_announcement_possible(card_id: int) -> bool:
	if is_legal(card_announcement(card_id, SelectionTarget.new())):
		return true
	return not card_targets(card_id).is_empty()


func is_hero_power_possible() -> bool:
	if is_legal(hero_power_announcement(SelectionTarget.new())):
		return true
	return not hero_power_targets().is_empty()


## La carte `card_id` de la main peut être jouée maintenant d'une manière au moins.
func is_card_playable(card_id: int) -> bool:
	if is_announced_card(card_id):
		return is_card_announcement_possible(card_id)
	return not deploy_cells(card_id).is_empty()


## Spell ou Gear : la carte s'annonce avec une cible plutôt qu'une case.
func is_announced_card(card_id: int) -> bool:
	var card_type := _card_type(card_id)
	return card_type == CardDefinition.CardType.SPELL or card_type == CardDefinition.CardType.GEAR


# Cibles de l'état pour lesquelles `intent_for(cible)` est légale.
func _legal_targets(intent_for: Callable) -> Array[SelectionTarget]:
	var targets: Array[SelectionTarget] = []
	for target: SelectionTarget in SelectionTarget.all_in(_engine.get_state()):
		var intent: DuelIntent = intent_for.call(target)
		if is_legal(intent):
			targets.append(target)
	return targets


func _card_type(card_id: int) -> CardDefinition.CardType:
	var card := _engine.get_state().get_player(_side).find_card_in_hand(card_id)
	return _engine.get_state().catalog.get_card(card.definition_id).card_type


func _copy_payment() -> EssencePayment:
	return EssencePayment.new(_payment.incline_count, _payment.recycle_count)
