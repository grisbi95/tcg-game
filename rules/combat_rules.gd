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
	var attacker_force := ForceRules.combat_force(state, attacker, ForceRules.CombatRole.ATTACKER)
	if defender.kind == Piece.PieceKind.HERO:
		_attack_hero(state, attacker, attacker_force, defender, events)
		return
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
		ActionRules.move_piece(attacker, defender_cell, events)


## 206.3.2, 206.3.2a, 202.2.13 : retire `piece` du plateau ; sa carte et son Gear vont dans la
## défausse de leur joueur, un jeton ne va nulle part ; 207.4.7a : ses effets « tant que la
## pièce est en jeu » cessent ; 210.3.2 : son Dernier souffle se déclenche.
static func destroy_piece(state: DuelState, piece: Piece, events: Array[DuelEvent]) -> void:
	state.pieces.erase(piece)
	EffectRules.end_effects_on_piece(state, piece, events)
	if piece.card != null:
		state.get_player(piece.card.owner).discard.append(piece.card)
	events.append(PieceDestroyed.new(piece.owner, piece.piece_id))
	if piece.attached_gear != null:
		var gear := piece.attached_gear
		state.get_player(gear.owner).discard.append(gear)
		events.append(CardDiscarded.new(gear.owner, gear.card_instance_id))
	TriggerRules.trigger(state, piece, EffectDefinition.TriggerEvent.DESTROYED, events)


# 206.2.1a, 206.4.2 à 206.4.5 : aucune Force comparée, rien de détruit, l'attaquant reste.
static func _attack_hero(
	state: DuelState, attacker: Piece, attacker_force: int, hero: Piece, events: Array[DuelEvent]
) -> void:
	events.append(HeroAttacked.new(hero.owner, attacker.piece_id, attacker_force))
	StateCheckRules.lose_health(state, hero.owner, attacker_force, events)


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
