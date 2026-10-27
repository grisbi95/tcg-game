class_name EffectDefinition
extends RefCounted
## Un effet d'un texte (EffectText) d'une carte ou d'un Hero : une action du vocabulaire fermé
## (décisions 0002, 0010, 0064). Le timing, l'événement déclencheur, « une fois par tour » et la
## condition lue à l'événement appartiennent au texte ; l'effet garde sa condition « si » (207.7.1)
## et « si vous le faites » (207.7.6).
##
## Aucune logique dans les données : le moteur interprète `kind`. Ajouter un `kind` : valeur à la
## fin de EffectKind, champs exigés dans `find_errors()`, code et tests dans le module du
## chapitre avant toute carte (rules/CLAUDE.md).

## Genres d'effet. Enum journalisable : ajouter à la fin, sans réordonner.
enum EffectKind {
	MODIFY_FORCE,  # amount, durée sauf statique ; cible pièce, pièce source ou portée statique
	DESTROY,  # cible pièce (206.3.1) ou pièce source (« détruisez ce Building »)
	COUNTER_SPELL,  # cible Spell de la pile (207.6)
	CREATE_TOKEN,  # token_piece_kind, token_force ; cible case (202.4)
	SWAP_CELLS,  # 214 : cible deux Units alliées (count 2), distinctes
	MOVE_UNIT,  # 215 : cible une Unit et, par `destination`, une case libre (décision 0056)
	RETURN_TO_HAND,  # 216 : cible une Unit
	DRAW_CARDS,  # amount ; sujet : le joueur à qui appartient l'effet (201.3.2, 209.5.2)
	DISCARD_CARDS,  # 212 : amount ; sujet : le joueur à qui appartient l'effet
	LOOK_AT_TOP_CARD,  # 217 : sujet : le joueur à qui appartient l'effet
	WAKE,  # 205.5 : cible une Unit, ou sujet : la pièce source (« cette Unit »)
	GRANT_KEYWORD,  # 210.4 : keyword (Assaut ou Rempart), amount ; mêmes formes que MODIFY_FORCE
	SLEEP,  # 205.5.7 : cible une Unit ou un Hero, ou sujet : la pièce source (« endormez cette Unit »)
}

## Quand l'effet a lieu.
enum EffectTiming {
	RESOLVE,  # à la résolution de l'entrée de la pile qui le porte (Spell)
	STATIC,  # 207.2 : sans pile, tant que la pièce qui le porte est en jeu
	TRIGGERED,  # 207.3 : ajouté à la pile quand survient `trigger`
}

## 207.3.1 : événements qui déclenchent un effet. Enum journalisable : ajouter à la fin.
enum TriggerEvent {
	NONE,
	ARRIVAL,  # 210.3.1
	DESTROYED,  # 210.3.2
	END_OF_TURN,  # 204.5.3 : quand le joueur actif termine son tour, à chaque tour
	START_OF_OWN_TURN,  # 204.3.12 : au début du tour du joueur à qui appartient l'effet
	OWN_SPELL_ANNOUNCED,  # le joueur à qui appartient l'effet annonce un Spell (208.4.4)
	OWN_CARD_DISCARDED,  # 212.2.4 : une carte de sa main est défaussée, un événement par carte
	DESTROYS_DEFENDER,  # 206.3.7 : la pièce, ou l'Unit qui porte le Gear, détruit son défenseur
}

## Ce que touche l'effet (décision 0057). Enum journalisable : ajouter à la fin.
enum EffectSubject {
	TARGETS,  # les cibles de `target` ; défaut, seul sujet d'un effet qui cible
	OWNER_PLAYER,  # le joueur à qui appartient l'effet, sans cible (212.1.2, 217.1.1)
	SOURCE_PIECE,  # la pièce qui porte l'effet (« cette Unit »), sans cible
	MATCHING_PIECES,  # décision 0064, 207.4.11 : l'ensemble décrit par `affected`, fixé à la pose
}

## Décision 0058 : d'où vient X quand un champ numérique de l'effet s'écrit « X » (213).
## Enum journalisable : ajouter à la fin.
enum XSource {
	NONE,
	CHOSEN,  # 213.1.3 : la valeur choisie à l'annonce du Spell à coût X
	TARGET_FORCE,  # 213.2.3 : la Force de la cible, lue une fois à la résolution
}

## Valeur de `token_force` quand l'effet ne crée pas de jeton.
const NO_TOKEN_FORCE: int = -1
## `token_piece_kind` non renseigné : un jeton n'est jamais un Hero (202.4.8).
const NO_TOKEN_KIND: Piece.PieceKind = Piece.PieceKind.HERO
## 214.1.3 : un échange cible deux Units.
const SWAP_TARGET_COUNT: int = 2
## 215.1.1 : un déplacement cible une Unit et une case.
const MOVE_TARGET_COUNT: int = 1
## Kinds à durée ou statiques : Force et mot-clé accordé.
const _LASTING_KINDS: Array[EffectKind] = [EffectKind.MODIFY_FORCE, EffectKind.GRANT_KEYWORD]
const _LASTING_TIMINGS: Array[EffectTiming] = [
	EffectTiming.RESOLVE, EffectTiming.STATIC, EffectTiming.TRIGGERED
]
const _ACTION_TIMINGS: Array[EffectTiming] = [EffectTiming.RESOLVE, EffectTiming.TRIGGERED]

var kind: EffectKind = EffectKind.MODIFY_FORCE
## 207.2.2, 207.2.8, décision 0062 : pièces que touche un effet statique, relativement à la pièce
## qui le porte (pour un Gear, la pièce à laquelle il est attaché) ; null hors effet statique.
var scope: PieceFilter
## 207.7.1, 207.7.1a, décision 0064 : condition « si » de l'effet, lue quand il vient dans l'ordre
## du texte d'un Spell ou d'un Ordre ; null sans condition.
var condition: EffectCondition
## 207.7.6, 207.7.6a, 207.7.6b : « si vous le faites » ; l'effet dépend de celui qui le précède
## immédiatement dans le texte.
var if_you_do: bool = false
## Décision 0064, 207.4.11 : pièces que touche un effet de sujet MATCHING_PIECES, sans les cibler,
## relativement à la pièce source ou au joueur ; null sinon.
var affected: PieceFilter
## Décision 0057 : ce que touche l'effet ; TARGETS quand il cible.
var subject: EffectSubject = EffectSubject.TARGETS
## Null pour un effet statique, qui ne cible pas (207.2.1), et pour un effet de sujet autre que
## TARGETS.
var target: TargetSpec
## 215.1.1, décision 0056 : case libre que cible MOVE_UNIT en plus de sa pièce ; null sinon.
var destination: TargetSpec
## 207.4.2 : présente seulement pour un effet non statique qui modifie la Force.
var has_duration: bool = false
var duration: ActiveEffect.EffectDuration = ActiveEffect.EffectDuration.UNTIL_END_OF_TURN
## Modificateur de Force pour MODIFY_FORCE ; 0 si sans objet.
var amount: int = 0
## Décision 0058 : `amount` s'écrit « X » ; sa valeur vient de `x_source`.
var amount_is_x: bool = false
## Décision 0058 : d'où vient X ; NONE si aucun champ de l'effet ne s'écrit « X ».
var x_source: XSource = XSource.NONE
## Mot-clé accordé par GRANT_KEYWORD (210.4) ; sans objet si `keyword_is_set` est faux.
var keyword: CardDefinition.Keyword = CardDefinition.Keyword.ASSAULT
var keyword_is_set: bool = false
var token_piece_kind: Piece.PieceKind = NO_TOKEN_KIND
var token_force: int = NO_TOKEN_FORCE
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Nom du `kind` tel que `ActiveEffect.effect_kind` le conserve : « modify_force ».
static func kind_id(effect_kind: EffectKind) -> StringName:
	return StringName(str(EffectKind.find_key(effect_kind)).to_lower())


## Lit un effet depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> EffectDefinition:
	var effect := EffectDefinition.new()
	var reader := CatalogReader.new(data)
	reader.require("kind", "207")
	var kind_value := reader.read_enum("kind", EffectKind)
	if kind_value != CatalogReader.NOT_SET:
		effect.kind = kind_value as EffectKind
	effect._read_conditions(reader)
	effect._read_parameters(reader)
	effect.parse_errors = reader.finish()
	return effect


# 207.2.1, 207.3.1, 207.4.10, 207.5.1 : le timing du texte (`text_timing`) exige ou interdit
# portée, cible et durée ; chaque kind exige ses paramètres et la cible qui lui convient.
func find_errors(text_timing: EffectTiming) -> PackedStringArray:
	var errors := parse_errors.duplicate()
	_check_timing(errors, text_timing)
	_check_conditions(errors, text_timing)
	_check_duration(errors, text_timing)
	_check_parameters(errors, text_timing)
	if target != null:
		for message: String in target.find_errors():
			errors.append("cible : " + message)
	if destination != null:
		for message: String in destination.find_errors():
			errors.append("destination : " + message)
	return errors


func _read_conditions(reader: CatalogReader) -> void:
	if reader.has("scope"):
		scope = PieceFilter.from_dict(reader.read_object("scope"))
	if reader.has("affected"):
		affected = PieceFilter.from_dict(reader.read_object("affected"))
	if reader.has("condition"):
		condition = EffectCondition.from_dict(reader.read_object("condition"))
	if_you_do = reader.read_bool("if_you_do", false)
	var subject_value := reader.read_enum("subject", EffectSubject)
	if subject_value != CatalogReader.NOT_SET:
		subject = subject_value as EffectSubject
	if reader.has("target"):
		target = TargetSpec.from_dict(reader.read_object("target"))
	if reader.has("destination"):
		destination = TargetSpec.from_dict(reader.read_object("destination"))


func _read_parameters(reader: CatalogReader) -> void:
	var duration_value := reader.read_enum("duration", ActiveEffect.EffectDuration)
	if duration_value != CatalogReader.NOT_SET:
		has_duration = true
		duration = duration_value as ActiveEffect.EffectDuration
	amount_is_x = reader.is_x("amount")
	if not amount_is_x:
		amount = reader.read_signed_int("amount", 0)
	var x_source_value := reader.read_enum("x_source", XSource)
	if x_source_value != CatalogReader.NOT_SET:
		x_source = x_source_value as XSource
	var keyword_value := reader.read_enum("keyword", CardDefinition.Keyword)
	if keyword_value != CatalogReader.NOT_SET:
		keyword = keyword_value as CardDefinition.Keyword
		keyword_is_set = true
	var token_kind_value := reader.read_enum("token_piece_kind", Piece.PieceKind)
	if token_kind_value != CatalogReader.NOT_SET:
		token_piece_kind = token_kind_value as Piece.PieceKind
	token_force = reader.read_int("token_force", CatalogReader.NON_NEGATIVE_MINIMUM, NO_TOKEN_FORCE)


func _timings_for_kind() -> Array[EffectTiming]:
	if kind in _LASTING_KINDS:
		return _LASTING_TIMINGS
	return _ACTION_TIMINGS


func _check_timing(errors: PackedStringArray, timing: EffectTiming) -> void:
	if _timings_for_kind().has(timing):
		return
	var kind_name := String(kind_id(kind))
	var timing_name := str(EffectTiming.find_key(timing)).to_lower()
	if kind == EffectKind.CREATE_TOKEN and timing == EffectTiming.STATIC:
		errors.append("202.4.7 : un effet statique ne crée pas de jeton")
	else:
		errors.append("207 : %s n'admet pas le timing %s" % [kind_name, timing_name])


func _check_conditions(errors: PackedStringArray, timing: EffectTiming) -> void:
	_check_sequence(errors, timing)
	_check_scope(errors, timing)
	if timing == EffectTiming.STATIC and target != null:
		errors.append("207.5.1 : un effet statique ne cible pas")
	if timing == EffectTiming.STATIC and subject != EffectSubject.TARGETS:
		errors.append("0057 : un effet statique ne nomme pas de sujet")
	var needs_target := timing != EffectTiming.STATIC and subject == EffectSubject.TARGETS
	if needs_target and target == null:
		errors.append("207.5.1 : un effet qui passe par la pile nomme sa cible")
	if subject != EffectSubject.TARGETS and target != null:
		errors.append("0057 : un effet dont le sujet n'est pas TARGETS ne nomme pas de cible")
	_check_subject(errors, timing)
	EffectTargetChecks.check_affected(self, errors)
	_check_source_adjacency(errors, timing)


# 207.7.1, 207.7.6, 207.7.6b : la condition « si » d'un effet vaut pour le texte d'un Spell ou d'un
# Ordre (timing RESOLVE) ; la condition d'un texte déclenché se lit à l'événement et s'écrit sur le
# texte (207.3.13). « Si vous le faites » n'est pas une condition « si » : les deux ne se
# combinent pas, le ruleset ne dit pas comment.
func _check_sequence(errors: PackedStringArray, timing: EffectTiming) -> void:
	if condition != null and timing != EffectTiming.RESOLVE:
		(
			errors
			. append(
				(
					"0064 : en attente d'une question du ruleset (voir 207.7.1, 207.3.13), la condition "
					+ "« si » d'un effet ne vaut que pour un Spell ou un Ordre"
				)
			)
		)
	if condition != null:
		for message: String in condition.find_errors():
			errors.append("condition : " + message)
	if if_you_do and timing == EffectTiming.STATIC:
		errors.append("207.7.6 : un effet statique ne dépend d'aucun autre effet")
	if if_you_do and condition != null:
		(
			errors
			. append(
				(
					"0064 : en attente d'une question du ruleset (voir 207.7.6b), « si vous le faites » "
					+ "et une condition « si » ne se combinent pas"
				)
			)
		)


# 207.2.2, 207.2.8, 206.5.5 : un effet statique nomme dans scope les pièces qu'il touche, relatives
# à la pièce qui le porte ; 202.3.9, Q-097 : sa Force ne touche aucun Hero.
func _check_scope(errors: PackedStringArray, timing: EffectTiming) -> void:
	if timing == EffectTiming.STATIC and scope == null:
		errors.append("207.2.2 : un effet statique nomme les pièces qu'il touche dans scope")
	if timing != EffectTiming.STATIC and scope != null:
		errors.append("207.2.1 : scope ne vaut que pour un effet statique")
	if scope == null:
		return
	for message: String in scope.find_errors():
		errors.append("scope : " + message)
	if scope.relative_to != PieceFilter.RelativeTo.SOURCE_PIECE:
		errors.append("207.2.8 : la portée d'un effet statique se lit par rapport à son porteur")
	if scope.piece_kinds.is_empty() and scope.relation != PieceFilter.Relation.SELF:
		errors.append("206.5.5 : une portée nomme au moins un genre dans piece_kinds")
	var touches_hero := scope.piece_kinds.has(Piece.PieceKind.HERO)
	if kind == EffectKind.MODIFY_FORCE and touches_hero:
		errors.append("202.3.9 : modify_force ne touche pas de Hero")


# 207.3.14 : un filtre relatif à la pièce source suppose une pièce qui porte l'effet, donc un texte
# déclenché.
func _check_source_adjacency(errors: PackedStringArray, timing: EffectTiming) -> void:
	var uses_source := [target, destination].any(
		func(spec: TargetSpec) -> bool: return spec != null and spec.uses_source_piece()
	)
	uses_source = uses_source or (affected != null and affected.uses_source_piece())
	if uses_source and timing != EffectTiming.TRIGGERED:
		errors.append(
			"207.3.14 : un filtre relatif à la pièce source ne vaut que pour un effet déclenché"
		)


# Décisions 0057, 0062 et 0064 : piocher, défausser et regarder touchent le joueur ; réveiller,
# endormir, modifier la Force, accorder un mot-clé et détruire, leurs cibles, la pièce source
# (effet déclenché seulement : un Spell n'a pas de pièce, un Ordre a celle du Hero) ou un ensemble
# décrit par `affected` (pas pour un effet statique, qui a sa portée) ; les autres kinds ciblent.
func _check_subject(errors: PackedStringArray, timing: EffectTiming) -> void:
	var allowed := _subjects_for_kind()
	if allowed.has(subject):
		var source_without_trigger := (
			subject == EffectSubject.SOURCE_PIECE and timing != EffectTiming.TRIGGERED
		)
		if source_without_trigger:
			errors.append("0057 : le sujet source_piece ne vaut que pour un effet déclenché")
		return
	var subject_name := str(EffectSubject.find_key(subject)).to_lower()
	errors.append("0057 : %s n'admet pas le sujet %s" % [String(kind_id(kind)), subject_name])


func _subjects_for_kind() -> Array[EffectSubject]:
	match kind:
		EffectKind.DRAW_CARDS, EffectKind.DISCARD_CARDS, EffectKind.LOOK_AT_TOP_CARD:
			return [EffectSubject.OWNER_PLAYER]
		EffectKind.WAKE, EffectKind.SLEEP, EffectKind.MODIFY_FORCE, EffectKind.DESTROY:
			return [
				EffectSubject.TARGETS, EffectSubject.SOURCE_PIECE, EffectSubject.MATCHING_PIECES
			]
		EffectKind.GRANT_KEYWORD:
			return [EffectSubject.TARGETS, EffectSubject.MATCHING_PIECES]
	return [EffectSubject.TARGETS]


func _check_duration(errors: PackedStringArray, timing: EffectTiming) -> void:
	if timing == EffectTiming.STATIC and has_duration:
		errors.append("207.4.10 : un effet statique n'a pas de durée")
	var lasting_kind := kind in _LASTING_KINDS
	var needs_duration := timing != EffectTiming.STATIC and lasting_kind
	if needs_duration and not has_duration:
		errors.append("207.4.2 : un effet de Force ou de mot-clé non statique porte une durée")
	if has_duration and not lasting_kind:
		errors.append("207.4.9 : sans durée, l'effet est ponctuel, duration est sans objet")


func _check_parameters(errors: PackedStringArray, timing: EffectTiming) -> void:
	_check_amount(errors)
	errors.append_array(EffectValueChecks.find_errors(self, timing))
	var creates_token := kind == EffectKind.CREATE_TOKEN
	if creates_token and token_piece_kind == NO_TOKEN_KIND:
		errors.append("202.4.8 : un jeton est une Unit ou un Building, token_piece_kind le dit")
	if creates_token and token_force == NO_TOKEN_FORCE:
		errors.append("202.4.9 : l'effet qui crée un jeton lui donne une Force, token_force")
	if not creates_token and (token_piece_kind != NO_TOKEN_KIND or token_force != NO_TOKEN_FORCE):
		errors.append("202.4.1 : token_piece_kind et token_force ne valent que pour CREATE_TOKEN")
	errors.append_array(EffectTargetChecks.find_errors(self))


# 206.5.1 : MODIFY_FORCE exige un modificateur non nul ; 201.3.2, 212.1.7 : piocher et défausser
# exigent un nombre de cartes positif ; les autres kinds n'ont pas d'amount.
func _check_amount(errors: PackedStringArray) -> void:
	if kind in [EffectKind.DRAW_CARDS, EffectKind.DISCARD_CARDS]:
		if amount < 1:
			errors.append("212.1.7 : amount est le nombre de cartes, au moins 1")
	elif kind == EffectKind.GRANT_KEYWORD:
		if not amount_is_x and amount < 1:
			errors.append("210.1.1 : amount est la valeur du mot-clé accordé, au moins 1")
	elif (kind == EffectKind.MODIFY_FORCE) != (amount != 0 or amount_is_x):
		errors.append("206.5.1 : amount est exigé non nul pour MODIFY_FORCE, absent sinon")
	if amount_is_x and kind not in _LASTING_KINDS:
		errors.append("0058 : amount « X » ne vaut que pour modify_force et grant_keyword")
