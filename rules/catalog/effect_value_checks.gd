class_name EffectValueChecks
extends RefCounted
## Contrôles de catalogue des valeurs X (213, décision 0058) et des mots-clés accordés (210.4) d'un
## EffectDefinition ; `EffectDefinition.find_errors()` les appelle, aucune règle de jeu ici.


## Erreurs de X et de mot-clé de `effect`.
static func find_errors(effect: EffectDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	_check_x(effect, errors)
	_check_keyword(effect, errors)
	return errors


## 213.1.3 : message d'erreur si des `effects` lisent le X choisi à l'annonce sans que la carte ait
## un coût X (`has_x_cost`), vide sinon.
static func chosen_x_error(effects: Array[EffectDefinition], has_x_cost: bool) -> String:
	var reads_chosen := effects.any(
		func(effect: EffectDefinition) -> bool:
			return effect.x_source == EffectDefinition.XSource.CHOSEN
	)
	if reads_chosen and not has_x_cost:
		return "213.1.3 : x_source chosen exige un Spell à coût X (cost « X »)"
	return ""


# Décision 0058, 213 : un champ « X » exige une source de X ; X choisi se lit dans la borne de Force
# d'une cible ou dans amount, X défini par un texte est la Force de l'unique Unit ciblée (213.2.3).
static func _check_x(effect: EffectDefinition, errors: PackedStringArray) -> void:
	var source := effect.x_source
	var limit_is_x := effect.target != null and effect.target.max_force_is_x
	var has_x_field := effect.amount_is_x or limit_is_x
	if has_x_field and source == EffectDefinition.XSource.NONE:
		errors.append("213 : un champ « X » exige x_source")
	if source != EffectDefinition.XSource.NONE and not has_x_field:
		errors.append("0058 : x_source exige un champ « X » (amount ou max_force)")
	if source != EffectDefinition.XSource.NONE:
		if effect.timing == EffectDefinition.EffectTiming.STATIC:
			errors.append("213.2.1 : un effet statique n'a pas de X")
	if limit_is_x and source != EffectDefinition.XSource.CHOSEN:
		errors.append("213.1.10 : max_force « X » exige x_source chosen")
	if source == EffectDefinition.XSource.TARGET_FORCE:
		_check_target_force_source(effect, errors)


# 213.2.3 : X est la Force d'une seule Unit ciblée.
static func _check_target_force_source(effect: EffectDefinition, errors: PackedStringArray) -> void:
	var target := effect.target
	var one_piece := (
		target != null
		and target.what == TargetSpec.TargetWhat.PIECE
		and target.count_max == 1
		and target.piece_filter.piece_kinds == [Piece.PieceKind.UNIT]
	)
	if not one_piece:
		errors.append("213.2.3 : x_source target_force lit la Force d'une seule Unit ciblée")


# 210.4.1c, 210.4.2c, décision 0058 : un effet accorde Assaut ou Rempart à une Unit.
static func _check_keyword(effect: EffectDefinition, errors: PackedStringArray) -> void:
	if effect.kind != EffectDefinition.EffectKind.GRANT_KEYWORD:
		if effect.keyword_is_set:
			errors.append("0058 : keyword ne vaut que pour grant_keyword")
		return
	var grantable: Array[CardDefinition.Keyword] = [
		CardDefinition.Keyword.ASSAULT, CardDefinition.Keyword.RAMPART
	]
	if not effect.keyword_is_set:
		errors.append("210.4 : grant_keyword nomme son mot-clé dans keyword")
	elif not grantable.has(effect.keyword):
		errors.append("0058 : grant_keyword n'accorde qu'Assaut ou Rempart")
	if effect.target != null and effect.target.piece_filter.piece_kinds != [Piece.PieceKind.UNIT]:
		errors.append("210.4.1c : grant_keyword ne cible que des Units")


## 210.4.1c, 210.4.2c : message d'erreur si un effet statique `BEARER` accordant un mot-clé figure
## parmi les `effects` d'une carte dont le porteur n'est pas une Unit (`bearer_is_unit`), vide
## sinon.
## Un Gear s'attache à une Unit : son porteur en est une.
static func bearer_grant_error(effects: Array[EffectDefinition], bearer_is_unit: bool) -> String:
	var refused := effects.any(
		func(effect: EffectDefinition) -> bool:
			return (
				effect.kind == EffectDefinition.EffectKind.GRANT_KEYWORD
				and effect.timing == EffectDefinition.EffectTiming.STATIC
				and effect.scope != null
				and effect.scope.relation == PieceFilter.Relation.SELF
			)
	)
	if refused and not bearer_is_unit:
		return "210.4.1c : un porteur qui n'est pas une Unit ne reçoit pas de mot-clé accordé"
	return ""
