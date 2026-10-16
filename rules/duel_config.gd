class_name DuelConfig
extends RefCounted
## Valeurs des règles PROVISOIRE, une par règle (décisions 0001 et 0007).
##
## Les valeurs par défaut sont celles de l'édition 0.28 du ruleset. Lecture seule pendant un
## duel : `DuelState.clone()` partage cette instance.

## 203.4.2 : valeur de `max_recycles_per_turn` quand le nombre de recyclages n'est pas borné.
const UNLIMITED_RECYCLES: int = -1

var max_hand_size: int = 7  # 201.3.4
var deck_size: int = 30  # 201.6.1
var max_copies_per_card: int = 3  # 201.6.2
var max_recycles_per_turn: int = UNLIMITED_RECYCLES  # 203.4.2
var total_sources_per_player: int = 10  # 203.5.7
var starting_sources: int = 2  # 204.1.2
var setup_sources_in_play: int = 2  # 204.1.12
var setup_sources_in_reserve: int = 8  # 204.1.13
var opening_hand_size: int = 5  # 204.1.15
var sources_received_per_turn: int = 1  # 204.3.1
var first_player_receives_source_on_first_turn: bool = false  # 204.3.4
var cards_drawn_per_turn: int = 2  # 204.3.6
## 206.3.6, dont 206.3.3a et 206.3.4a portent le statut : option A de la décision 0053 du
## ruleset, seule définie par les règles ; `find_errors()` refuse toute autre valeur.
var tie_destroys_both: bool = true
var clock_duration_msec: int = 600_000  # 209.4.3 : 10 minutes
var clock_bonus_msec: int = 0  # 209.4.3a
var starting_fatigue: int = 0  # 209.5.1
var fatigue_increase: int = 1  # 209.5.2
var fatigue_damage_per_counter_point: int = 1  # 209.5.3


## Renvoie les incohérences entre valeurs qui se recoupent (203.5.7, 204.1.2, 204.1.12,
## 204.1.13) et les valeurs que les règles ne définissent pas (206.3.6) ; vide si la
## configuration est cohérente.
func find_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var setup_total := setup_sources_in_play + setup_sources_in_reserve
	if starting_sources != setup_sources_in_play:
		errors.append("204.1.2 et 204.1.12 diffèrent")
	if setup_total != total_sources_per_player:
		errors.append(
			"204.1.12 + 204.1.13 = %d, 203.5.7 = %d" % [setup_total, total_sources_per_player]
		)
	if not tie_destroys_both:
		errors.append("206.3.6 : seule l'option A de la décision 0053 est définie par les règles")
	return errors
