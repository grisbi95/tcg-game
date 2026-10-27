class_name KeywordGranted
extends PlayerEvent
## 210.4, décision 0058 : un effet à durée accorde Assaut ou Rempart à une pièce du joueur.

var piece_id: int = DuelState.NO_ID
var keyword: CardDefinition.Keyword = CardDefinition.Keyword.ASSAULT
var amount: int = 0
## Effet à durée créé dans l'état (`DuelState.active_effects`), renseigné après la construction.
var effect_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	granted_piece_id: int = DuelState.NO_ID,
	granted_keyword: CardDefinition.Keyword = CardDefinition.Keyword.ASSAULT,
	keyword_value: int = 0
) -> void:
	super(concerned_player)
	piece_id = granted_piece_id
	keyword = granted_keyword
	amount = keyword_value
