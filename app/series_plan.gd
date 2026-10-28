class_name SeriesPlan
extends RefCounted
## Plan de série lu dans `data/series/` (décision 0069) : les parties du protocole, numérotées à
## partir de 1 dans l'ordre de lecture ; l'ordre de jeu n'est pas fixé (Q-142 du ruleset).

const FIRST_GAME_NUMBER: int = 1

var edition: String = ""
## Dans l'ordre des numéros, de `FIRST_GAME_NUMBER` à `game_count()`.
var games: Array[SeriesPlanGame] = []


func game_count() -> int:
	return games.size()


## Partie de numéro `game_number` ; null si le plan ne l'a pas.
func find_game(game_number: int) -> SeriesPlanGame:
	for game: SeriesPlanGame in games:
		if game.game_number == game_number:
			return game
	return null
