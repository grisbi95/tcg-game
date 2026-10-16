class_name DuelSetup
extends RefCounted
## Données de démarrage d'un duel (décision 0012) : decks, Heroes, graine, premier joueur.
##
## Sans premier joueur imposé, il est tiré au sort après le mulligan (204.1.14, 204.1.16).

## Identifiants de cartes du catalogue ; le dernier est le sommet du deck avant le mélange.
var deck_a: Array[StringName] = []
var deck_b: Array[StringName] = []
var hero_a: StringName = &""
var hero_b: StringName = &""
var rng_seed: int = 0
var is_first_player_imposed: bool = false
var imposed_first_player: DuelState.PlayerSide = DuelState.PlayerSide.A


## Décision 0012 : le premier joueur ne sera pas tiré au sort.
func impose_first_player(side: DuelState.PlayerSide) -> void:
	is_first_player_imposed = true
	imposed_first_player = side


func deck_of(side: DuelState.PlayerSide) -> Array[StringName]:
	return deck_a if side == DuelState.PlayerSide.A else deck_b


func hero_of(side: DuelState.PlayerSide) -> StringName:
	return hero_a if side == DuelState.PlayerSide.A else hero_b


## 201.6, 202.3 : raisons qui empêchent le duel de démarrer ; vide si le setup est valide.
func find_errors(catalog: Catalog, config: DuelConfig) -> PackedStringArray:
	var errors := PackedStringArray()
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var label := "Joueur %s" % DuelState.PlayerSide.find_key(side)
		if catalog.get_hero(hero_of(side)) == null:
			errors.append("%s : Hero « %s » absent du catalogue" % [label, hero_of(side)])
		for error: String in catalog.find_deck_errors(deck_of(side), config):
			errors.append("%s : %s" % [label, error])
	return errors
