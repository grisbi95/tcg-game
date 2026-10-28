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


## Annonce de la carte `card_id`, un Spell ou un Gear, avec `target` et, pour un coût X, `x_value`.
func card_announcement(card_id: int, target: SelectionTarget, x_value: int = 0) -> DuelIntent:
	if _card_type(card_id) == CardDefinition.CardType.GEAR:
		var unit_id: int = DuelState.NO_ID
		if not target.piece_ids.is_empty():
			unit_id = target.piece_ids[0]
		return AttachGear.new(_side, card_id, unit_id, _copy_payment())
	var cast := CastSpell.new(_side, card_id, _copy_payment())
	cast.x_value = x_value
	target.assign_to(cast)
	return cast


## Annonce de l'Ordre de rang `order_index` du Hero, avec `target`.
func order_announcement(order_index: int, target: SelectionTarget) -> AnnounceOrder:
	var announcement := AnnounceOrder.new(_side, order_index, _copy_payment())
	target.assign_to(announcement)
	return announcement


## Réponse à l'attente CHOOSE_TARGETS, avec `target`.
func targets_answer(target: SelectionTarget) -> ChooseTargets:
	var answer := ChooseTargets.new(_side)
	target.assign_to(answer)
	return answer


func deploy(card_id: int, cell: Vector2i) -> DeployCard:
	return DeployCard.new(_side, card_id, cell, _copy_payment())


func normal_action(piece_id: int, cell: Vector2i) -> TakeNormalAction:
	return TakeNormalAction.new(_side, piece_id, cell)


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


## Assistant de l'annonce de la carte `card_id` (décision 0068), pas encore commencée.
func card_assistant(card_id: int) -> AnnouncementAssistant:
	var assistant := AnnouncementAssistant.new()
	assistant.setup(
		_engine,
		func(target: SelectionTarget, x_value: int) -> DuelIntent:
			return card_announcement(card_id, target, x_value),
		_has_x_cost(card_id)
	)
	return assistant


## Assistant de l'annonce de l'Ordre de rang `order_index` du Hero.
func order_assistant(order_index: int) -> AnnouncementAssistant:
	var assistant := AnnouncementAssistant.new()
	assistant.setup(
		_engine,
		func(target: SelectionTarget, _x_value: int) -> DuelIntent:
			return order_announcement(order_index, target),
		false
	)
	return assistant


## Assistant de la réponse à l'attente CHOOSE_TARGETS.
func answer_assistant() -> AnnouncementAssistant:
	var assistant := AnnouncementAssistant.new()
	assistant.setup(
		_engine,
		func(target: SelectionTarget, _x_value: int) -> DuelIntent: return targets_answer(target),
		false
	)
	return assistant


## Décision 0068 : valeurs des boutons de choix : les places de la carte regardée quand le moteur
## attend ce choix de ce joueur (217.1.2, 217.1.3), sinon les Ordres que le Hero `piece_id` peut
## annoncer (vide sans pièce choisie).
func choice_values(piece_id: int) -> Array[int]:
	var values: Array[int] = []
	if looked_card_id() != DuelState.NO_ID:
		for place: ChooseTopCardPlace.TopCardPlace in ChooseTopCardPlace.TopCardPlace.values():
			values.append(place)
	elif piece_id != DuelState.NO_ID:
		values = announceable_orders(piece_id)
	return values


## 217.1.1 : carte du dessus du deck que ce joueur regarde maintenant, sinon NO_ID.
func looked_card_id() -> int:
	return DuelViewModel.looked_card_id(_engine.get_state(), _side)


## La pièce `piece_id` a un geste à proposer : une action normale, ou un Ordre du Hero.
func has_piece_gesture(piece_id: int) -> bool:
	return not move_cells(piece_id).is_empty() or not announceable_orders(piece_id).is_empty()


## Rangs des Ordres du Hero `piece_id` qu'on peut annoncer maintenant ; vide pour toute autre pièce.
func announceable_orders(piece_id: int) -> Array[int]:
	var order_indexes: Array[int] = []
	var piece := _engine.get_state().find_piece(piece_id)
	if piece == null or piece.kind != Piece.PieceKind.HERO or piece.owner != _side:
		return order_indexes
	for order_index: int in OrderRules.order_count(_engine.get_state(), _side):
		if order_assistant(order_index).is_announceable():
			order_indexes.append(order_index)
	return order_indexes


## La carte `card_id` de la main peut être jouée maintenant d'une manière au moins.
func is_card_playable(card_id: int) -> bool:
	if is_announced_card(card_id):
		return card_assistant(card_id).is_announceable()
	return not deploy_cells(card_id).is_empty()


## La carte s'annonce avec une cible plutôt qu'une case : le moteur le dit (`CardRules`).
func is_announced_card(card_id: int) -> bool:
	return _engine.announces_with_target(card_id)


# Cibles de l'état pour lesquelles `intent_for(cible)` est légale.
func _legal_targets(intent_for: Callable) -> Array[SelectionTarget]:
	var targets: Array[SelectionTarget] = []
	for target: SelectionTarget in SelectionTarget.all_in(_engine.get_state()):
		var intent: DuelIntent = intent_for.call(target)
		if is_legal(intent):
			targets.append(target)
	return targets


func _has_x_cost(card_id: int) -> bool:
	var card := _engine.get_state().get_player(_side).find_card_in_hand(card_id)
	return _engine.get_state().catalog.get_card(card.definition_id).has_x_cost


func _card_type(card_id: int) -> CardDefinition.CardType:
	var card := _engine.get_state().get_player(_side).find_card_in_hand(card_id)
	return _engine.get_state().catalog.get_card(card.definition_id).card_type


func _copy_payment() -> EssencePayment:
	return EssencePayment.new(_payment.incline_count, _payment.recycle_count)
