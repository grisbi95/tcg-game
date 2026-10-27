class_name SwapRules
extends RefCounted
## Échanger les cases de deux Units (214). Les cibles (deux Units alliées distinctes) sont jugées
## par EffectRules (207.5) ; EffectRules.resolve_effect appelle `resolve`.
##
## L'échange n'endort ni ne réveille (214.2.2), n'est pas l'action normale (214.2.3), ne fait pas
## arriver les pièces et ne déclenche aucune Arrivée (214.2.4) : rien ici ne touche à
## `is_awake` ni à TriggerRules.


## 207.5.3, 207.5.4a, 214.2.1, 200.4.2a : l'échange n'a lieu que si les deux cibles sont restées
## valides ; sans aucune, l'effet n'a pas lieu (207.5.5).
static func resolve(context: EffectContext) -> void:
	var pieces := EffectRules.valid_pieces(context.state, context.entry, context.effect.target)
	if pieces.is_empty():
		EffectRules.lose_all_targets(context.entry, context.events)
	elif pieces.size() == EffectDefinition.SWAP_TARGET_COUNT:
		context.took_place = true
		swap_cells(context.entry.owner, pieces[0], pieces[1], context.events)


## 214.1.1, 214.1.2 : `first` et `second` occupent chacune la case de l'autre, en même temps.
## 214.2.5 : ce n'est pas un déplacement, l'événement est PiecesSwapped et non PieceMoved.
static func swap_cells(
	owner: DuelState.PlayerSide, first: Piece, second: Piece, events: Array[DuelEvent]
) -> void:
	var swapped := PiecesSwapped.new(owner, first.piece_id, second.piece_id)
	swapped.first_cell = first.cell
	swapped.second_cell = second.cell
	first.cell = swapped.second_cell
	second.cell = swapped.first_cell
	events.append(swapped)
