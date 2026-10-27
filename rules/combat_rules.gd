class_name CombatRules
extends RefCounted
## Combat (206) : comparaison des Forces, issue, attaque du Hero, destruction.
##
## Appelé par la résolution d'un déploiement (205.1.6) ou d'une action normale (205.2.3).


## 206.1.1, 206.1.2, 206.2.2, 206.5.2 : `attacker` attaque `defender`. Les Forces se lisent
## une fois, avant que l'attaquant change de case, Assaut et Rempart compris (210.4.1b,
## 210.4.2b).
static func resolve_attack(
	state: DuelState, attacker: Piece, defender: Piece, events: Array[DuelEvent]
) -> void:
	if defender.kind == Piece.PieceKind.HERO:
		_attack_hero(state, attacker, defender, events)
		return
	var attacker_force := _attacker_force(state, attacker)
	var defender_force := ForceRules.combat_force(state, defender, ForceRules.CombatRole.DEFENDER)
	events.append(
		CombatResolved.new(attacker.piece_id, defender.piece_id, attacker_force, defender_force)
	)
	var defender_cell := defender.cell
	var defender_destroyed := _is_defender_destroyed(state, attacker_force, defender_force)
	# 206.3.3 ; 206.3.3a : à l'égalité, l'attaquant est détruit lui aussi (206.3.6), en même temps
	# que le défenseur (207.3.15).
	var attacker_destroyed := _is_attacker_destroyed(state, attacker_force, defender_force)
	var destroyed: Array[Piece] = []
	if defender_destroyed:
		destroyed.append(defender)
	if attacker_destroyed:
		destroyed.append(attacker)
	destroy_pieces(state, destroyed, events)
	if defender_destroyed and not attacker_destroyed:
		ZoneRules.move_piece(attacker, defender_cell, events)
		_trigger_destroys_defender(state, attacker, events)


## 206.3.2, 206.3.2a, 202.2.13 : détruit `piece` ; voir `destroy_pieces`.
static func destroy_piece(state: DuelState, piece: Piece, events: Array[DuelEvent]) -> void:
	destroy_pieces(state, [piece], events)


## 206.3.2, 206.3.2a, 202.2.13 : retire `pieces` du plateau, en même temps ; la carte et le Gear de
## chacune vont dans la défausse de leur joueur, un jeton ne va nulle part ; 207.4.7a : ses effets
## « tant que la pièce est en jeu » cessent ; 210.3.2 : son Dernier souffle se déclenche.
## 207.3.15 : les effets « une autre pièce est détruite » des pièces en jeu avant la destruction,
## celles qui sont détruites avec elles comprises, se déclenchent une fois toutes parties.
static func destroy_pieces(
	state: DuelState, pieces: Array[Piece], events: Array[DuelEvent]
) -> void:
	if pieces.is_empty():
		return
	var reactors := state.pieces_on_board()
	for piece: Piece in pieces:
		_destroy(state, piece, events)
	TriggerRules.trigger_other_destroyed(state, pieces, reactors, events)


# 206.3.2 : une pièce quitte le plateau.
static func _destroy(state: DuelState, piece: Piece, events: Array[DuelEvent]) -> void:
	ZoneRules.remove_piece(state, piece)
	ModifierRules.end_effects_on_piece(state, piece, events)
	if piece.card != null:
		state.get_player(piece.card.owner).discard.append(piece.card)
	events.append(PieceDestroyed.new(piece.owner, piece.piece_id))
	ZoneRules.discard_attached_gear(state, piece, events)
	TriggerRules.trigger(state, piece, EffectDefinition.TriggerEvent.DESTROYED, events)


# 206.3.7, 206.3.7a, 206.3.7b : une Unit qui attaque détruit son défenseur quand le défenseur est
# détruit sans qu'elle le soit ; l'égalité (qui les détruit tous deux) et l'attaque d'un Hero
# (`_attack_hero`) n'y mènent pas. L'effet de l'Unit et celui de son Gear se déclenchent (207.3.12).
static func _trigger_destroys_defender(
	state: DuelState, attacker: Piece, events: Array[DuelEvent]
) -> void:
	if attacker.kind == Piece.PieceKind.UNIT:
		TriggerRules.trigger(
			state, attacker, EffectDefinition.TriggerEvent.DESTROYS_DEFENDER, events
		)


# 206.2.1a, 206.4.2 à 206.4.5 : aucune Force comparée, rien de détruit, l'attaquant reste.
static func _attack_hero(
	state: DuelState, attacker: Piece, hero: Piece, events: Array[DuelEvent]
) -> void:
	var attacker_force := _attacker_force(state, attacker)
	events.append(HeroAttacked.new(hero.owner, attacker.piece_id, attacker_force))
	StateCheckRules.lose_health(state, hero.owner, attacker_force, events)


# 206.1.1, 206.2.2, 206.5.2 ; 210.4.1b : Force de l'attaquant, lue avant qu'il change de case.
static func _attacker_force(state: DuelState, attacker: Piece) -> int:
	return ForceRules.combat_force(state, attacker, ForceRules.CombatRole.ATTACKER)


# 206.3.1 ; égalité : 206.3.6 et 206.3.4a (DuelConfig.tie_destroys_both).
static func _is_defender_destroyed(
	state: DuelState, attacker_force: int, defender_force: int
) -> bool:
	if attacker_force != defender_force:
		return attacker_force > defender_force
	return state.config.tie_destroys_both


# 206.3.1, 206.3.4 ; égalité : 206.3.6 (DuelConfig.tie_destroys_both).
static func _is_attacker_destroyed(
	state: DuelState, attacker_force: int, defender_force: int
) -> bool:
	if attacker_force != defender_force:
		return attacker_force < defender_force
	return state.config.tie_destroys_both
