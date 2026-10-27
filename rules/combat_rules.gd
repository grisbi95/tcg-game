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
	if defender_destroyed:
		destroy_piece(state, defender, events)
	# 206.3.3 ; 206.3.3a : à l'égalité, l'attaquant est détruit lui aussi (206.3.6).
	if _is_attacker_destroyed(state, attacker_force, defender_force):
		destroy_piece(state, attacker, events)
	elif defender_destroyed:
		ZoneRules.move_piece(attacker, defender_cell, events)
		_trigger_destroys_defender(state, attacker, events)


## 206.3.2, 206.3.2a, 202.2.13 : retire `piece` du plateau ; sa carte et son Gear vont dans la
## défausse de leur joueur, un jeton ne va nulle part ; 207.4.7a : ses effets « tant que la
## pièce est en jeu » cessent ; 210.3.2 : son Dernier souffle se déclenche.
static func destroy_piece(state: DuelState, piece: Piece, events: Array[DuelEvent]) -> void:
	ZoneRules.remove_piece(state, piece)
	EffectRules.end_effects_on_piece(state, piece, events)
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
