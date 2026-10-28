class_name AnnouncementAssistant
extends RefCounted
## Assistant d'annonce (décision 0068) : pour une annonce commencée (Spell, Gear, Ordre du Hero) ou
## pour la réponse à CHOOSE_TARGETS, enchaîne les étapes dans l'ordre de la carte, X d'abord s'il y
## a un coût X (213.1.9), puis chaque cible, et ne rend l'intention que complète et légale (0031).
##
## Aucune règle ici : chaque candidat est une cible pour laquelle `DuelEngine.validate()` accepte
## l'intention, ou après laquelle il en accepte une avec une cible de plus. L'intention se fabrique
## par `intent_for(cible, x)`, fournie par le parent. Au plus `MAX_TARGET_COUNT` cibles.

## Où en est l'annonce. Ajouter à la fin, sans réordonner.
enum Step {
	NONE,  # rien d'annonçable : l'annonce n'a pas commencé
	X_CHOICE,  # valeur de X à choisir, ses cibles déjà proposées pour la valeur courante
	TARGET_CHOICE,  # cible à choisir
}

## Plus grande valeur de X essayée : borne de la recherche, jamais une règle.
const X_SEARCH_LIMIT: int = 30
# 213.1.4
const FIRST_X_TRIED: int = 1
const MAX_TARGET_COUNT: int = 2
const PAYMENT_REASONS: Array[IntentRejected.RejectReason] = [
	IntentRejected.RejectReason.NEGATIVE_PAYMENT,
	IntentRejected.RejectReason.PAYMENT_DOES_NOT_MATCH_COST,
	IntentRejected.RejectReason.NOT_ENOUGH_UPRIGHT_SOURCES,
	IntentRejected.RejectReason.NOT_ENOUGH_TILTED_SOURCES,
	IntentRejected.RejectReason.RECYCLE_LIMIT_REACHED,
]

var _engine: DuelEngine
var _intent_for: Callable
var _has_x_cost: bool = false
var _step: Step = Step.NONE
var _playable_x_values: Array[int] = []
var _x_index: int = 0
var _chosen: SelectionTarget = SelectionTarget.new()
var _candidates: Array[SelectionTarget] = []
var _signature: Array[int] = []


## `intent_for` est un `Callable(cible: SelectionTarget, x_value: int) -> DuelIntent`.
func setup(engine: DuelEngine, intent_for: Callable, with_x_cost: bool) -> void:
	_engine = engine
	_intent_for = intent_for
	_has_x_cost = with_x_cost


## Commence l'annonce. Rend l'intention si elle est complète aussitôt (sans X ni cible), sinon
## null : `get_step()` dit alors ce qui est demandé, ou NONE si rien n'est annonçable.
func start() -> DuelIntent:
	_signature = _current_signature()
	_chosen = SelectionTarget.new()
	_step = Step.NONE
	if _has_x_cost:
		_playable_x_values = _scan_playable_x_values(X_SEARCH_LIMIT)
		_x_index = 0
		if not _playable_x_values.is_empty():
			_step = Step.X_CHOICE
			_refresh_candidates()
		return null
	var untargeted := _build(SelectionTarget.new(), 0)
	if _is_legal(untargeted):
		return untargeted
	_refresh_candidates()
	if not _candidates.is_empty():
		_step = Step.TARGET_CHOICE
	return null


## L'annonce est possible d'une manière au moins (sans rien mémoriser).
func is_announceable() -> bool:
	var empty := SelectionTarget.new()
	if not _has_x_cost:
		return _is_legal(_build(empty, 0)) or not _extensions_of(empty, 0).is_empty()
	return not _scan_playable_x_values(1).is_empty()


func get_step() -> Step:
	return _step


func has_x_cost() -> bool:
	return _has_x_cost


func get_x_value() -> int:
	return _playable_x_values[_x_index] if _has_x_cost else 0


## Plus petite valeur de X que le moteur accepte.
func get_x_min() -> int:
	return _playable_x_values.front() if _has_x_cost else 0


## Plus grande valeur de X que le moteur accepte.
func get_x_max() -> int:
	return _playable_x_values.back() if _has_x_cost else 0


## X ne se change plus une fois la première cible choisie (213.1.9 : X avant les cibles).
func can_decrease_x() -> bool:
	return _step == Step.X_CHOICE and _x_index > 0


func can_increase_x() -> bool:
	return _step == Step.X_CHOICE and _x_index < _playable_x_values.size() - 1


func decrease_x() -> void:
	if can_decrease_x():
		_x_index -= 1
		_refresh_candidates()


func increase_x() -> void:
	if can_increase_x():
		_x_index += 1
		_refresh_candidates()


## L'annonce sans cible est légale avec la valeur de X courante.
func can_confirm_x() -> bool:
	return _step == Step.X_CHOICE and _is_legal(_build(SelectionTarget.new(), get_x_value()))


## Rend l'annonce sans cible avec la valeur de X courante, si le moteur l'accepte.
func confirm_x() -> DuelIntent:
	if not can_confirm_x():
		return null
	return _build(SelectionTarget.new(), get_x_value())


## Cibles proposées à cette étape.
func get_candidates() -> Array[SelectionTarget]:
	return _candidates


## Cibles déjà choisies.
func get_chosen() -> SelectionTarget:
	return _chosen


func is_candidate(target: SelectionTarget) -> bool:
	return _candidates.any(func(each: SelectionTarget) -> bool: return each.is_same_as(target))


## Choisit `target`, qui doit être un candidat. Rend l'intention quand elle est complète et légale,
## sinon null : l'étape suivante est alors prête, ou NONE si plus rien n'est possible.
func choose(target: SelectionTarget) -> DuelIntent:
	if _step == Step.NONE or not is_candidate(target):
		return null
	_chosen = _chosen.merged_with(target)
	_step = Step.TARGET_CHOICE
	var intent := _build(_chosen, get_x_value())
	if _is_legal(intent):
		return intent
	_refresh_candidates()
	if _candidates.is_empty():
		_step = Step.NONE
	return null


## L'état du duel a changé depuis le début de l'annonce (tour, priorité, pile, attente) : le temps
## a pu expirer, l'annonce est abandonnée (209.4.11).
func is_stale() -> bool:
	return _signature != _current_signature()


func _build(target: SelectionTarget, x_value: int) -> DuelIntent:
	return _intent_for.call(target, x_value)


func _is_legal(intent: DuelIntent) -> bool:
	return _engine.validate(intent) == IntentRejected.RejectReason.NONE


func _current_signature() -> Array[int]:
	var state := _engine.get_state()
	var decision_id := DuelState.NO_ID
	if state.pending_decision != null:
		decision_id = state.pending_decision.subject_stack_entry_id
	return [
		state.turn_number,
		state.active_player,
		state.priority_player,
		state.stack.size(),
		decision_id,
	]


func _refresh_candidates() -> void:
	_candidates = _extensions_of(_chosen, get_x_value())


# Les `max_count` premières valeurs de X que le moteur accepte.
func _scan_playable_x_values(max_count: int) -> Array[int]:
	var values: Array[int] = []
	for x_value: int in range(FIRST_X_TRIED, X_SEARCH_LIMIT + 1):
		if _is_x_playable(x_value):
			values.append(x_value)
			if values.size() >= max_count:
				break
	return values


# Le coût de X se paie à l'annonce : un refus de paiement écarte la valeur sans chercher de cible.
func _is_x_playable(x_value: int) -> bool:
	var empty := SelectionTarget.new()
	var reason := _engine.validate(_build(empty, x_value))
	if reason == IntentRejected.RejectReason.NONE:
		return true
	if PAYMENT_REASONS.has(reason):
		return false
	return not _extensions_of(empty, x_value).is_empty()


# Cibles qui complètent `prefix` en une annonce légale ; à défaut, celles après lesquelles une autre
# cible la complète (le déplacement : une pièce puis une case). Un seul genre à la fois.
func _extensions_of(prefix: SelectionTarget, x_value: int) -> Array[SelectionTarget]:
	var all_targets := SelectionTarget.all_in(_engine.get_state())
	var completing: Array[SelectionTarget] = []
	for target: SelectionTarget in all_targets:
		if prefix.overlaps(target):
			continue
		if _is_legal(_build(prefix.merged_with(target), x_value)):
			completing.append(target)
	if not completing.is_empty() or prefix.count() + 1 >= MAX_TARGET_COUNT:
		return _first_kind_only(completing)
	var leading: Array[SelectionTarget] = []
	for target: SelectionTarget in all_targets:
		if prefix.overlaps(target):
			continue
		if _has_completion(prefix.merged_with(target), x_value, all_targets):
			leading.append(target)
	return _first_kind_only(leading)


func _has_completion(
	prefix: SelectionTarget, x_value: int, all_targets: Array[SelectionTarget]
) -> bool:
	for target: SelectionTarget in all_targets:
		if not prefix.overlaps(target) and _is_legal(_build(prefix.merged_with(target), x_value)):
			return true
	return false


func _first_kind_only(targets: Array[SelectionTarget]) -> Array[SelectionTarget]:
	var first_kind: int = SelectionTarget.TargetKind.STACK_ENTRY
	for target: SelectionTarget in targets:
		first_kind = mini(first_kind, target.kind())
	return targets.filter(func(target: SelectionTarget) -> bool: return target.kind() == first_kind)
