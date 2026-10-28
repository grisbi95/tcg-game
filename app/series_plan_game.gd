class_name SeriesPlanGame
extends RefCounted
## Une partie du plan de série (décision 0069 ; protocole, « Plan de série », décisions de design
## 0230 et 0231) : son numéro, le deck de chaque joueur et le premier joueur imposé.

var game_number: int = 0
var deck_id_a: StringName = &""
var deck_id_b: StringName = &""
var first_player: DuelState.PlayerSide = DuelState.PlayerSide.A


## Identifiant du deck que tient le joueur `side`.
func deck_id(side: DuelState.PlayerSide) -> StringName:
	return deck_id_a if side == DuelState.PlayerSide.A else deck_id_b
