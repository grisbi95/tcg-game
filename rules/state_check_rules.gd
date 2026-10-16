class_name StateCheckRules
extends RefCounted
## Contrôles d'état (209) : à l'étape 1.3, la fatigue (209.5) et le plancher de PV (209.2.4).
##
## La fin de partie quand un Hero atteint 0 PV (209.2.2) vient à l'étape 1.4.


## 209.5.2, 209.5.2a, 209.5.3 : `side` doit piocher alors que son deck est vide, même main
## pleine ; son compteur de fatigue augmente et son Hero perd la nouvelle valeur en PV.
static func apply_fatigue(
	state: DuelState, side: DuelState.PlayerSide, events: Array[DuelEvent]
) -> void:
	var player := state.get_player(side)
	player.fatigue_counter += state.config.fatigue_increase
	events.append(FatigueIncreased.new(side, player.fatigue_counter))
	var health_to_lose := player.fatigue_counter * state.config.fatigue_damage_per_counter_point
	_lose_health(state, side, health_to_lose, events)


# 209.2.4 ; 200.4.2 : le Hero ne perd que les PV qu'il a, l'événement donne la perte réelle.
static func _lose_health(
	state: DuelState, side: DuelState.PlayerSide, amount: int, events: Array[DuelEvent]
) -> void:
	var hero := state.find_hero(side)
	var lost_health := mini(amount, hero.health)
	hero.health -= lost_health
	events.append(HeroLostHealth.new(side, lost_health))
