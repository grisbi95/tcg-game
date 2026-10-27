class_name EffectTargetChecks
extends RefCounted
## Contrôles de catalogue de la cible qu'un `kind` d'effet exige (202.3.9, 205.5.6, 207.5.11, 214 à
## 216, décisions 0056 et 0057) ; `EffectDefinition.find_errors()` les appelle, aucune règle de jeu
## ici.


## Erreurs de cible de `effect`.
static func find_errors(effect: EffectDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	_check_target_what(effect, errors)
	_check_hero_target(effect, errors)
	_check_movement(effect, errors)
	_check_wake(effect, errors)
	return errors


static func _check_target_what(effect: EffectDefinition, errors: PackedStringArray) -> void:
	if effect.target == null:
		return
	var expected := _expected_target_what(effect)
	if effect.target.what != expected:
		var expected_name := str(TargetSpec.TargetWhat.find_key(expected)).to_lower()
		var kind_name := String(EffectDefinition.kind_id(effect.kind))
		errors.append("%s : %s cible %s" % [_target_rule(effect), kind_name, expected_name])


# 202.3.9, 206.4.3 : ni la Force ni la destruction d'un Hero ne sont tranchées par le ruleset ;
# un effet de Force ou de destruction ne vise donc pas de Hero.
static func _check_hero_target(effect: EffectDefinition, errors: PackedStringArray) -> void:
	var target := effect.target
	if target == null or not target.piece_kinds.has(Piece.PieceKind.HERO):
		return
	var kinds: Array[EffectDefinition.EffectKind] = [
		EffectDefinition.EffectKind.MODIFY_FORCE, EffectDefinition.EffectKind.DESTROY
	]
	if effect.kind in kinds:
		errors.append(
			"202.3.9 : %s ne vise pas de Hero" % String(EffectDefinition.kind_id(effect.kind))
		)


# 214.1.3, 214.1.4, 215.1.1, 216.1.1, décision 0056 : les trois effets de mouvement ciblent des
# Units ; l'échange en cible deux alliées ; le déplacement nomme sa case de destination.
static func _check_movement(effect: EffectDefinition, errors: PackedStringArray) -> void:
	var movements: Array[EffectDefinition.EffectKind] = [
		EffectDefinition.EffectKind.SWAP_CELLS,
		EffectDefinition.EffectKind.MOVE_UNIT,
		EffectDefinition.EffectKind.RETURN_TO_HAND
	]
	var target := effect.target
	if effect.destination != null and effect.kind != EffectDefinition.EffectKind.MOVE_UNIT:
		errors.append("215.1.1 : destination ne vaut que pour MOVE_UNIT")
	if target != null and target.adjacent_to == TargetSpec.AdjacentTo.TARGET_PIECE:
		errors.append("215.1.1 : target_piece ne vaut que pour la destination")
	if effect.kind not in movements or target == null:
		return
	var kind_name := String(EffectDefinition.kind_id(effect.kind))
	if target.what == TargetSpec.TargetWhat.PIECE and target.piece_kinds != [Piece.PieceKind.UNIT]:
		errors.append("%s : %s ne cible que des Units" % [_target_rule(effect), kind_name])
	if effect.kind == EffectDefinition.EffectKind.SWAP_CELLS:
		_check_swap(target, errors)
	if effect.kind == EffectDefinition.EffectKind.MOVE_UNIT:
		_check_move(effect, errors)


# Glossaire (Réveiller), 205.5.1, 205.5.2, 205.5.6 : un effet réveille une Unit ou un Hero, jamais
# un Building, qui n'est ni endormi ni éveillé ; `piece_kinds` le dit.
static func _check_wake(effect: EffectDefinition, errors: PackedStringArray) -> void:
	var target := effect.target
	if effect.kind != EffectDefinition.EffectKind.WAKE or target == null:
		return
	if target.what != TargetSpec.TargetWhat.PIECE:
		return
	var wakeable := not target.piece_kinds.is_empty()
	for piece_kind: Piece.PieceKind in target.piece_kinds:
		wakeable = wakeable and piece_kind != Piece.PieceKind.BUILDING
	if not wakeable:
		errors.append("205.5.6 : wake ne cible que des Units ou des Heroes, nommés par piece_kinds")


# 214.1.3, 214.1.4 : exactement deux Units alliées.
static func _check_swap(target: TargetSpec, errors: PackedStringArray) -> void:
	if target.side != TargetSpec.TargetSide.ALLY:
		errors.append("214.1.3 : swap_cells ne cible que des Units alliées")
	if (
		target.count_min != EffectDefinition.SWAP_TARGET_COUNT
		or target.count_max != EffectDefinition.SWAP_TARGET_COUNT
	):
		errors.append("214.1.4 : swap_cells cible exactement deux Units")


# 215.1.1 : une Unit et une case libre.
static func _check_move(effect: EffectDefinition, errors: PackedStringArray) -> void:
	var target := effect.target
	var destination := effect.destination
	if (
		target.count_min != EffectDefinition.MOVE_TARGET_COUNT
		or target.count_max != EffectDefinition.MOVE_TARGET_COUNT
	):
		errors.append("215.1.1 : move_unit cible une seule Unit")
	if destination == null:
		errors.append("215.1.1 : move_unit nomme sa case de destination dans destination")
		return
	if destination.what != TargetSpec.TargetWhat.CELL:
		errors.append("215.1.1 : la destination de move_unit est une case")
	var one_cell := (
		destination.count_min == EffectDefinition.MOVE_TARGET_COUNT
		and destination.count_max == EffectDefinition.MOVE_TARGET_COUNT
	)
	if not one_cell:
		errors.append("215.1.1 : move_unit a une seule case de destination")


static func _target_rule(effect: EffectDefinition) -> String:
	match effect.kind:
		EffectDefinition.EffectKind.SWAP_CELLS:
			return "214.1.4"
		EffectDefinition.EffectKind.MOVE_UNIT:
			return "215.1.1"
		EffectDefinition.EffectKind.RETURN_TO_HAND:
			return "216.1.1"
		EffectDefinition.EffectKind.COUNTER_SPELL:
			return "207.6.2"
		EffectDefinition.EffectKind.CREATE_TOKEN:
			return "202.4.12"
	return "207.5.11"


static func _expected_target_what(effect: EffectDefinition) -> TargetSpec.TargetWhat:
	match effect.kind:
		EffectDefinition.EffectKind.COUNTER_SPELL:
			return TargetSpec.TargetWhat.SPELL_ON_STACK  # 207.6.2
		EffectDefinition.EffectKind.CREATE_TOKEN:
			return TargetSpec.TargetWhat.CELL  # 202.4.12
	return TargetSpec.TargetWhat.PIECE
