class_name StateCheckRules
extends RefCounted
## Contrôles d'état (209) : victoire et partie nulle (209.2, 209.3), abandon, inactivité
## (209.2.10), temps de tour et de réponse (209.4), fatigue (209.5).
##
## Décisions 0018 et 0045 : le moteur ne lit jamais l'heure ; l'hôte lui signale le temps écoulé.
## Les conséquences d'une expiration (fin du tour, passe, choix abandonné) sont aiguillées par
## DuelEngine vers le module de leur chapitre.


## 209.2.5 : un joueur peut abandonner à tout moment ; seule une partie non commencée ou
## terminée se refuse, contrôlée par DuelEngine. Pur.
static func validate_concede(_state: DuelState, _intent: Concede) -> IntentRejected.RejectReason:
	return IntentRejected.RejectReason.NONE


## 201.1.3a, 209.2.6, 209.2.7 : le joueur qui abandonne perd ; la partie s'arrête aussitôt.
static func apply_concede(state: DuelState, intent: Concede, events: Array[DuelEvent]) -> void:
	events.append(PlayerConceded.new(intent.player))
	_end_duel(
		state, _win_for(DuelState.opponent_of(intent.player)), DuelState.EndReason.CONCEDED, events
	)


## 201.1.2, 201.1.2a, 209.2.1, 209.2.2, 209.3.1 : arrête la partie si un Hero a 0 PV et
## renvoie vrai ; sinon ne change rien et renvoie faux. Une partie déjà arrêtée le reste, sans
## nouvel événement. `reason` est la raison portée par DuelEnded (décision 0040), toujours
## explicite.
static func check_victory(
	state: DuelState, events: Array[DuelEvent], reason: DuelState.EndReason
) -> bool:
	if state.is_ended():
		return true
	var a_down := state.find_hero(DuelState.PlayerSide.A).health == 0
	var b_down := state.find_hero(DuelState.PlayerSide.B).health == 0
	if not a_down and not b_down:
		return false
	if a_down and b_down:
		_end_duel(state, DuelState.DuelResult.DRAW, reason, events)
	else:
		var loser := DuelState.PlayerSide.A if a_down else DuelState.PlayerSide.B
		_end_duel(state, _win_for(DuelState.opponent_of(loser)), reason, events)
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
	_take_health(state, side, health_to_lose, events)
	check_victory(state, events, DuelState.EndReason.HERO_HEALTH_ZERO_BY_FATIGUE)


## 209.2.1, 209.2.2, 209.2.4 ; 200.4.2 : avec `apply_fatigue`, seule voie de perte de PV d'un
## Hero, par `_take_health` puis `check_victory`. Il ne perd que les PV qu'il a, l'événement donne
## la perte réelle, puis la victoire se vérifie.
static func lose_health(
	state: DuelState, side: DuelState.PlayerSide, amount: int, events: Array[DuelEvent]
) -> void:
	_take_health(state, side, amount, events)
	check_victory(state, events, DuelState.EndReason.HERO_HEALTH_ZERO)


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


## 209.4.2, 209.4.2a à 209.4.2d, 209.4.4, décision 0018 : joueurs dont un temps s'écoule, ceux
## dont une décision est attendue, sauf pendant le mulligan. Pur.
static func clock_owners(state: DuelState) -> Array[DuelState.PlayerSide]:
	var owners: Array[DuelState.PlayerSide] = []
	var decision := state.pending_decision
	if decision != null and decision.kind == PendingDecision.DecisionKind.MULLIGAN:
		return owners
	return awaited_players(state)


## 209.4.4, 209.4.7, 209.4.7b, 209.4.8 : le temps de `side` qui s'écoule quand une décision est
## attendue de lui : son temps de tour si c'est le joueur actif et que la pile est vide, sinon son
## temps de réponse. Pur.
static func clock_kind(state: DuelState, side: DuelState.PlayerSide) -> DuelState.ClockKind:
	if side == state.active_player and state.stack.is_empty():
		return DuelState.ClockKind.TURN
	return DuelState.ClockKind.RESPONSE


## 209.4.8 : le temps de tour du joueur actif est en pause tant que la pile n'est pas vide. Pur.
static func is_turn_time_paused(state: DuelState, side: DuelState.PlayerSide) -> bool:
	return side == state.active_player and not state.stack.is_empty()


## 209.4.3, 209.4.6 : temps restant du compteur de `side` qui s'écoule (ou s'écoulerait) ; un
## joueur dont aucune décision n'est attendue recevra un temps de réponse complet. Pur.
static func running_time_remaining_msec(state: DuelState, side: DuelState.PlayerSide) -> int:
	var player := state.get_player(side)
	if clock_kind(state, side) == DuelState.ClockKind.TURN:
		return player.turn_time_remaining_msec
	if not awaited_players(state).has(side):
		return state.config.response_time_msec
	return player.response_time_remaining_msec


## 209.4.2, 209.4.8, 209.4.8a, décision 0018 : retire jusqu'à `elapsed_msec` aux compteurs qui
## s'écoulent, sans descendre sous 0, et renvoie le temps retiré. Le temps de tour d'un joueur
## dont la pile n'est pas vide ne bouge pas. Un temps nul ou négatif ne change rien.
static func spend_time(state: DuelState, elapsed_msec: int) -> int:
	var owners := clock_owners(state)
	if elapsed_msec <= 0 or owners.is_empty():
		return 0
	var consumed_msec := elapsed_msec
	for side: DuelState.PlayerSide in owners:
		consumed_msec = mini(consumed_msec, running_time_remaining_msec(state, side))
	for side: DuelState.PlayerSide in owners:
		var player := state.get_player(side)
		if clock_kind(state, side) == DuelState.ClockKind.TURN:
			player.turn_time_remaining_msec -= consumed_msec
		else:
			player.response_time_remaining_msec -= consumed_msec
	return consumed_msec


## 209.4.9, 209.4.10 : joueurs dont le compteur qui s'écoule est à 0. Pur.
static func expired_owners(state: DuelState) -> Array[DuelState.PlayerSide]:
	var expired: Array[DuelState.PlayerSide] = []
	for side: DuelState.PlayerSide in clock_owners(state):
		if running_time_remaining_msec(state, side) == 0:
			expired.append(side)
	return expired


## 209.2.10 : un tour que son joueur termine lui-même interrompt la suite de tours inactifs.
static func record_turn_ended_by_player(state: DuelState, side: DuelState.PlayerSide) -> void:
	state.get_player(side).idle_turns = 0


## 209.2.10, 201.1.3d : un tour terminé par l'expiration du temps de tour (209.4.9) sans annonce
## compte comme tour inactif ; après une annonce, la suite repart de 0. Au nombre de tours
## inactifs de `DuelConfig.idle_turns_limit`, `side` perd la partie.
static func record_turn_expired(
	state: DuelState, side: DuelState.PlayerSide, events: Array[DuelEvent]
) -> void:
	var player := state.get_player(side)
	if player.announced_this_turn:
		player.idle_turns = 0
		return
	player.idle_turns += 1
	if player.idle_turns < state.config.idle_turns_limit:
		return
	events.append(IdleDefeat.new(side))
	_end_duel(state, _win_for(DuelState.opponent_of(side)), DuelState.EndReason.IDLE_TURNS, events)


# 209.2.2, 209.2.3, 209.2.7 : plus rien n'est attendu ni résolu ; la pile reste en l'état.
static func _end_duel(
	state: DuelState,
	result: DuelState.DuelResult,
	reason: DuelState.EndReason,
	events: Array[DuelEvent]
) -> void:
	state.phase = DuelState.DuelPhase.ENDED
	state.result = result
	state.pending_decision = null
	events.append(DuelEnded.new(result, reason))


# 209.2.4 : le Hero ne perd que les PV qu'il a ; l'événement donne la perte réelle.
static func _take_health(
	state: DuelState, side: DuelState.PlayerSide, amount: int, events: Array[DuelEvent]
) -> void:
	var hero := state.find_hero(side)
	var lost_health := mini(amount, hero.health)
	hero.health -= lost_health
	events.append(HeroLostHealth.new(side, lost_health))


static func _win_for(side: DuelState.PlayerSide) -> DuelState.DuelResult:
	if side == DuelState.PlayerSide.A:
		return DuelState.DuelResult.PLAYER_A_WINS
	return DuelState.DuelResult.PLAYER_B_WINS
