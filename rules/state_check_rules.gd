class_name StateCheckRules
extends RefCounted
## Contrôles d'état (209) : victoire et partie nulle (209.2, 209.3), abandon, pendule (209.4),
## fatigue (209.5).
##
## Décision 0018 : le moteur ne lit jamais l'heure ; l'hôte lui signale le temps écoulé.


## 209.2.5 : un joueur peut abandonner à tout moment ; seule une partie non commencée ou
## terminée se refuse, contrôlée par DuelEngine. Pur.
static func validate_concede(_state: DuelState, _intent: Concede) -> IntentRejected.RejectReason:
	return IntentRejected.RejectReason.NONE


## 201.1.3a, 209.2.6, 209.2.7 : le joueur qui abandonne perd ; la partie s'arrête aussitôt.
static func apply_concede(state: DuelState, intent: Concede, events: Array[DuelEvent]) -> void:
	events.append(PlayerConceded.new(intent.player))
	_end_duel(state, _win_for(DuelState.opponent_of(intent.player)), events)


## 201.1.2, 201.1.2a, 209.2.1, 209.2.2, 209.3.1 : arrête la partie si un Hero a 0 PV et
## renvoie vrai ; sinon ne change rien et renvoie faux. Une partie déjà arrêtée le reste, sans
## nouvel événement.
static func check_victory(state: DuelState, events: Array[DuelEvent]) -> bool:
	if state.is_ended():
		return true
	var a_down := state.find_hero(DuelState.PlayerSide.A).health == 0
	var b_down := state.find_hero(DuelState.PlayerSide.B).health == 0
	if not a_down and not b_down:
		return false
	if a_down and b_down:
		_end_duel(state, DuelState.DuelResult.DRAW, events)
	else:
		var loser := DuelState.PlayerSide.A if a_down else DuelState.PlayerSide.B
		_end_duel(state, _win_for(DuelState.opponent_of(loser)), events)
	return true


## 209.5.2, 209.5.2a, 209.5.3 : `side` doit piocher alors que son deck est vide, même main
## pleine ; son compteur de fatigue augmente et son Hero perd la nouvelle valeur en PV, ce qui
## peut arrêter la partie (209.2.2).
static func apply_fatigue(
	state: DuelState, side: DuelState.PlayerSide, events: Array[DuelEvent]
) -> void:
	var player := state.get_player(side)
	player.fatigue_counter += state.config.fatigue_increase
	events.append(FatigueIncreased.new(side, player.fatigue_counter))
	var health_to_lose := player.fatigue_counter * state.config.fatigue_damage_per_counter_point
	lose_health(state, side, health_to_lose, events)


## 209.2.1, 209.2.2, 209.2.4 ; 200.4.2 : seule voie de perte de PV d'un Hero. Il ne perd que les
## PV qu'il a, l'événement donne la perte réelle, puis la victoire se vérifie.
static func lose_health(
	state: DuelState, side: DuelState.PlayerSide, amount: int, events: Array[DuelEvent]
) -> void:
	var hero := state.find_hero(side)
	var lost_health := mini(amount, hero.health)
	hero.health -= lost_health
	events.append(HeroLostHealth.new(side, lost_health))
	check_victory(state, events)


## 209.4.4, 209.4.4a à 209.4.4d, 204.2.2 : joueurs dont les règles attendent une décision, dans
## l'ordre de DuelState.SIDES ; les deux pendant le mulligan. Vide hors duel et pendant la
## résolution de la pile, qui a lieu dans un `submit()`. Pur.
static func awaited_players(state: DuelState) -> Array[DuelState.PlayerSide]:
	var awaited: Array[DuelState.PlayerSide] = []
	if state.phase == DuelState.DuelPhase.NOT_STARTED or state.is_ended():
		return awaited
	if state.pending_decision != null:
		for side: DuelState.PlayerSide in DuelState.SIDES:
			if state.pending_decision.awaited_players.has(side):
				awaited.append(side)
	elif not state.stack.is_empty():
		awaited.append(state.priority_player)
	elif state.phase == DuelState.DuelPhase.MAIN:
		awaited.append(state.active_player)
	return awaited


## 209.4.2, 209.4.2a à 209.4.2d, 209.4.4, décision 0018 : joueurs dont la pendule tourne, ceux
## dont une décision est attendue, sauf pendant le mulligan. Pur.
static func clock_owners(state: DuelState) -> Array[DuelState.PlayerSide]:
	var owners: Array[DuelState.PlayerSide] = []
	var decision := state.pending_decision
	if decision != null and decision.kind == PendingDecision.DecisionKind.MULLIGAN:
		return owners
	return awaited_players(state)


## 209.4.2, 209.4.5, 209.2.9, décision 0018 : retire `elapsed_msec` aux pendules qui tournent,
## sans descendre sous 0. Une pendule qui atteint 0 arrête la partie à cet instant : les autres
## ne perdent que le temps écoulé jusque-là. Un temps nul ou négatif ne change rien.
static func advance_clock(state: DuelState, elapsed_msec: int, events: Array[DuelEvent]) -> void:
	var owners := clock_owners(state)
	if elapsed_msec <= 0 or owners.is_empty():
		return
	var consumed_msec := elapsed_msec
	for side: DuelState.PlayerSide in owners:
		consumed_msec = mini(consumed_msec, state.get_player(side).clock_remaining_msec)
	var expired: Array[DuelState.PlayerSide] = []
	for side: DuelState.PlayerSide in owners:
		var player := state.get_player(side)
		player.clock_remaining_msec -= consumed_msec
		if player.clock_remaining_msec == 0:
			expired.append(side)
	_end_on_time(state, expired, events)


# 209.2.8 : le joueur dont le temps est écoulé perd ; 209.2.8a : les deux en même temps, nulle ;
# 209.2.9 : la partie s'arrête aussitôt.
static func _end_on_time(
	state: DuelState, expired: Array[DuelState.PlayerSide], events: Array[DuelEvent]
) -> void:
	if expired.is_empty():
		return
	for side: DuelState.PlayerSide in expired:
		events.append(TimeExpired.new(side))
	if expired.size() == DuelState.PLAYER_COUNT:
		_end_duel(state, DuelState.DuelResult.DRAW, events)
	else:
		_end_duel(state, _win_for(DuelState.opponent_of(expired[0])), events)


# 209.2.2, 209.2.3, 209.2.7 : plus rien n'est attendu ni résolu ; la pile reste en l'état.
static func _end_duel(
	state: DuelState, result: DuelState.DuelResult, events: Array[DuelEvent]
) -> void:
	state.phase = DuelState.DuelPhase.ENDED
	state.result = result
	state.pending_decision = null
	events.append(DuelEnded.new(result))


static func _win_for(side: DuelState.PlayerSide) -> DuelState.DuelResult:
	if side == DuelState.PlayerSide.A:
		return DuelState.DuelResult.PLAYER_A_WINS
	return DuelState.DuelResult.PLAYER_B_WINS
