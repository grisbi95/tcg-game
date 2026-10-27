class_name EffectValueChecks
extends RefCounted
## Contrôles de catalogue des valeurs X (213, décisions 0058 et 0065), des valeurs du jeu lues par
## les conditions et des mots-clés accordés (210.4) ; `EffectDefinition.find_errors()` et
## `EffectText.find_errors()` les appellent, aucune règle de jeu ici.

## Où se lit une valeur du jeu (décision 0065).
enum Use {
	EVENT_CONDITION,  # condition d'un texte déclenché, lue à l'événement (207.3.13)
	STEP_CONDITION,  # condition « si » d'un effet, lue dans l'ordre du texte (207.7.1a)
	AMOUNT,  # « X » d'un champ numérique de l'effet, lu à la résolution (213.2.1)
	FORCE_LIMIT,  # « X » de la Force maximale d'une cible, lu à l'annonce (213.1.10)
}

const _SOURCE_FORCE_PENDING: String = (
	"en attente d'une question du ruleset (voir 207.3.3, 213.2.3, 200.4.1) : "
	+ "la Force de la pièce source ne se lit pas"
)


## Erreurs de X et de mot-clé de `effect`, effet d'un texte de timing `timing`.
static func find_errors(
	effect: EffectDefinition, timing: EffectDefinition.EffectTiming
) -> PackedStringArray:
	var errors := PackedStringArray()
	_check_x(effect, timing, errors)
	_check_keyword(effect, errors)
	return errors


## Décision 0065 : erreurs des valeurs du jeu que lit `text` (condition à l'événement, conditions
## « si » de ses effets, « X » de ses effets) selon le moment où chacune se lit.
static func text_errors(text: EffectText) -> PackedStringArray:
	var errors := PackedStringArray()
	if text.condition != null:
		errors.append_array(
			value_errors(text.condition.value, Use.EVENT_CONDITION, text.trigger, null)
		)
	for index: int in text.effects.size():
		var effect := text.effects[index]
		var previous: EffectDefinition = text.effects[index - 1] if index > 0 else null
		if effect.condition != null:
			errors.append_array(
				value_errors(effect.condition.value, Use.STEP_CONDITION, text.trigger, previous)
			)
		if effect.x_from != null:
			var use := Use.FORCE_LIMIT if _limit_is_x(effect) else Use.AMOUNT
			errors.append_array(value_errors(effect.x_from, use, text.trigger, previous))
	return errors


## Décision 0065 : erreurs de `value` lue en `use` par un texte déclenché par `trigger` (NONE pour
## un Spell, un Ordre ou un texte statique), `previous` étant l'effet qui précède dans le texte
## (null au premier). Une valeur qui n'a pas de sens à ce moment est refusée.
static func value_errors(
	value: GameValue, use: Use, trigger: EffectDefinition.TriggerEvent, previous: EffectDefinition
) -> PackedStringArray:
	var errors := value.find_errors()
	var is_event := use == Use.EVENT_CONDITION
	match value.kind:
		GameValue.Kind.PIECE_COUNT:
			if value.uses_source_piece() and trigger == EffectDefinition.TriggerEvent.NONE:
				errors.append(
					"207.3.14 : un filtre relatif à la pièce source ne vaut que déclenché"
				)
		GameValue.Kind.SOURCE_FORCE:
			errors.append(_SOURCE_FORCE_PENDING)
		GameValue.Kind.TARGET_FORCE:
			if use != Use.AMOUNT:
				errors.append("0065 : la Force de la cible ne se lit que dans « X » d'un montant")
		GameValue.Kind.DISCARDED_BY_PREVIOUS_EFFECT:
			var after_discard := (
				previous != null and previous.kind == EffectDefinition.EffectKind.DISCARD_CARDS
			)
			if is_event or not after_discard:
				errors.append("0065 : les cartes défaussées se lisent après un effet qui défausse")
		GameValue.Kind.CHOSEN_X:
			if is_event:
				errors.append("0065 : X choisi ne se lit pas dans une condition à l'événement")
		GameValue.Kind.EVENT_SPELL_COST:
			if not (is_event and _is_spell_trigger(trigger)):
				(
					errors
					. append(
						(
							"0065 : le coût du Spell de l'événement ne se lit que dans la condition d'un "
							+ "texte déclenché par l'annonce ou le contrecarrage d'un Spell"
						)
					)
				)
	if use == Use.FORCE_LIMIT and value.kind != GameValue.Kind.CHOSEN_X:
		errors.append("213.1.10 : max_force « X » exige x_from chosen_x")
	return errors


## 213.1.3 : message d'erreur si des `texts` lisent le X choisi à l'annonce sans que la carte ait
## un coût X (`has_x_cost`), vide sinon.
static func chosen_x_error(texts: Array[EffectText], has_x_cost: bool) -> String:
	if _reads_value(texts, GameValue.Kind.CHOSEN_X) and not has_x_cost:
		return "213.1.3 : x_from chosen_x exige un Spell à coût X (cost « X »)"
	return ""


# Décision 0058, 213 : un champ « X » exige la valeur du jeu x_from qui le donne ; X choisi se lit
# dans la borne de Force d'une cible ou dans amount, la Force de la cible est celle de l'unique
# Unit ciblée (213.2.3).
static func _check_x(
	effect: EffectDefinition, timing: EffectDefinition.EffectTiming, errors: PackedStringArray
) -> void:
	var has_x_field := effect.amount_is_x or _limit_is_x(effect)
	if has_x_field and effect.x_from == null:
		errors.append("213 : un champ « X » exige x_from")
	if effect.x_from == null:
		return
	if not has_x_field:
		errors.append("0065 : x_from exige un champ « X » (amount ou max_force)")
	if timing == EffectDefinition.EffectTiming.STATIC:
		errors.append("213.2.1 : un effet statique n'a pas de X")
	if effect.x_from.kind == GameValue.Kind.TARGET_FORCE:
		_check_target_force_source(effect, errors)


static func _limit_is_x(effect: EffectDefinition) -> bool:
	return effect.target != null and effect.target.max_force_is_x


static func _reads_value(texts: Array[EffectText], kind: GameValue.Kind) -> bool:
	return texts.any(
		func(text: EffectText) -> bool:
			return text.game_values().any(func(value: GameValue) -> bool: return value.kind == kind)
	)


static func _is_spell_trigger(trigger: EffectDefinition.TriggerEvent) -> bool:
	return (
		trigger == EffectDefinition.TriggerEvent.OWN_SPELL_ANNOUNCED
		or trigger == EffectDefinition.TriggerEvent.SPELL_COUNTERED
	)


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
		errors.append("213.2.3 : x_from target_force lit la Force d'une seule Unit ciblée")


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
## parmi les `texts` d'une carte dont le porteur n'est pas une Unit (`bearer_is_unit`), vide sinon.
## Un Gear s'attache à une Unit : son porteur en est une.
static func bearer_grant_error(texts: Array[EffectText], bearer_is_unit: bool) -> String:
	var static_effects: Array[EffectDefinition] = []
	for text: EffectText in texts:
		if text.timing == EffectDefinition.EffectTiming.STATIC:
			static_effects.append_array(text.effects)
	var refused := static_effects.any(
		func(effect: EffectDefinition) -> bool:
			return (
				effect.kind == EffectDefinition.EffectKind.GRANT_KEYWORD
				and effect.scope != null
				and effect.scope.relation == PieceFilter.Relation.SELF
			)
	)
	if refused and not bearer_is_unit:
		return "210.4.1c : un porteur qui n'est pas une Unit ne reçoit pas de mot-clé accordé"
	return ""
