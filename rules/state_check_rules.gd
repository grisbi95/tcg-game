class_name StateCheckRules
extends RefCounted
## Contrôles d'état (209) : victoire et partie nulle (209.2, 209.3), abandon, fatigue (209.5).
##
## La pendule (209.4) vient à l'étape 1.8.


## 209.2.5 : un joueur peut abandonner à tout moment ; seule une partie en cours se refuse,
## contrôlée par DuelEngine. Pur.
static func validate_concede(_state: DuelState, _intent: Concede) -> IntentRejected.RejectReason:
	return IntentRejected.RejectReason.NONE


## 201.1.3a, 209.2.6, 209.2.7 : le joueur qui abandonne perd ; la partie s'arrête aussitôt.
static func apply_concede(state: DuelState, intent: Concede, events: Array[DuelEvent]) -> void:
	events.append(PlayerConceded.new(intent.player))
	_end_duel(state, _win_for(DuelState.opponent_of(intent.player)), events)


## 201.1.2, 201.1.2a, 209.2.1, 209.2.2, 209.3.1 : arrête la partie si un Hero a 0 PV et
## renvoie vrai ; sinon ne change rien et renvoie faux.
static func check_victory(state: DuelState, events: Array[DuelEvent]) -> bool:
	var a_down := state.find_hero(DuelState.PlayerSide.A).health == 0
	var b_down := state.find_hero(DuelState.PlayerSide.B).health == 0
	if not a_down and not b_down:
		return false
	if a_down and b_down:
		_end_duel(state, DuelState.DuelResult.DRAW, events)
	elif a_down:
		_end_duel(state, _win_for(DuelState.PlayerSide.B), events)
	else:
		_end_duel(state, _win_for(DuelState.PlayerSide.A), events)
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
	_lose_health(state, side, health_to_lose, events)
	check_victory(state, events)


# 209.2.4 ; 200.4.2 : le Hero ne perd que les PV qu'il a, l'événement donne la perte réelle.
static func _lose_health(
	state: DuelState, side: DuelState.PlayerSide, amount: int, events: Array[DuelEvent]
) -> void:
	var hero := state.find_hero(side)
	var lost_health := mini(amount, hero.health)
	hero.health -= lost_health
	events.append(HeroLostHealth.new(side, lost_health))


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
