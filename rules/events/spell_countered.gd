class_name SpellCountered
extends PlayerEvent
## 207.6.4, 207.6.5 : un Spell du joueur est contrecarré et sa carte va dans sa défausse.

var stack_entry_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	countered_entry_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	stack_entry_id = countered_entry_id
