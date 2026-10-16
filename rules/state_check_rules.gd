class_name StateCheckRules
extends RefCounted
## Contrôles d'état (209) : à l'étape 1.3, la fatigue (209.5) seulement.
##
## La victoire d'un joueur dont l'adversaire n'a plus de PV (209.2) vient à l'étape 1.4.


## 209.5.2, 209.5.2a, 209.5.3 : `side` doit piocher alors que son deck est vide, même main
## pleine ; son compteur de fatigue augmente et son Hero perd la nouvelle valeur en PV.
static func apply_fatigue(
	state: DuelState, side: DuelState.PlayerSide, events: Array[DuelEvent]
) -> void:
	var player := state.get_player(side)
	player.fatigue_counter += state.config.fatigue_increase
	events.append(FatigueIncreased.new(side, player.fatigue_counter))
	var lost_health := player.fatigue_counter * state.config.fatigue_damage_per_counter_point
	state.find_hero(side).health -= lost_health
	events.append(HeroLostHealth.new(side, lost_health))
