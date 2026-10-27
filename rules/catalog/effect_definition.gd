class_name EffectDefinition
extends RefCounted
## Un effet d'une carte ou d'un Hero : une action du vocabulaire fermé (décisions 0002, 0010).
##
## Aucune logique dans les données : le moteur interprète `kind`. Ajouter un `kind` : valeur à la
## fin de EffectKind, champs exigés dans `find_errors()`, code et tests dans le module du
## chapitre avant toute carte (rules/CLAUDE.md).

## Genres d'effet. Enum journalisable : ajouter à la fin, sans réordonner.
enum EffectKind {
	MODIFY_FORCE,  # amount, durée sauf statique ; cible pièce ou portée statique
	DESTROY,  # cible pièce (206.3.1)
	COUNTER_SPELL,  # cible Spell de la pile (207.6)
	CREATE_TOKEN,  # token_piece_kind, token_force ; cible case (202.4)
	SWAP_CELLS,  # 214 : cible deux Units alliées (count 2), distinctes
	MOVE_UNIT,  # 215 : cible une Unit et, par `destination`, une case libre (décision 0056)
	RETURN_TO_HAND,  # 216 : cible une Unit
	DRAW_CARDS,  # amount ; sujet : le joueur à qui appartient l'effet (201.3.2, 209.5.2)
	DISCARD_CARDS,  # 212 : amount ; sujet : le joueur à qui appartient l'effet
	LOOK_AT_TOP_CARD,  # 217 : sujet : le joueur à qui appartient l'effet
	WAKE,  # 205.5 : cible une Unit, ou sujet : la pièce source (« cette Unit »)
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
}

## 207.2 : pièces que touche un effet statique, relativement à la pièce qui le porte.
enum StaticScope {
	NONE,
	BEARER,  # la pièce qui porte l'effet (207.2.8 : pour un Gear, la pièce à laquelle il est attaché)
	ADJACENT_ALLIED_UNITS,  # les Units alliées adjacentes à la pièce qui porte l'effet
}

## Ce que touche l'effet (décision 0057). Enum journalisable : ajouter à la fin.
enum EffectSubject {
	TARGETS,  # les cibles de `target` ; défaut, seul sujet d'un effet qui cible
	OWNER_PLAYER,  # le joueur à qui appartient l'effet, sans cible (212.1.2, 217.1.1)
	SOURCE_PIECE,  # la pièce qui porte l'effet (« cette Unit »), sans cible
}

## Valeur de `token_force` quand l'effet ne crée pas de jeton.
const NO_TOKEN_FORCE: int = -1
## `token_piece_kind` non renseigné : un jeton n'est jamais un Hero (202.4.8).
const NO_TOKEN_KIND: Piece.PieceKind = Piece.PieceKind.HERO
## 214.1.3 : un échange cible deux Units.
const SWAP_TARGET_COUNT: int = 2
## 215.1.1 : un déplacement cible une Unit et une case.
const MOVE_TARGET_COUNT: int = 1
const _MODIFY_FORCE_TIMINGS: Array[EffectTiming] = [
	EffectTiming.RESOLVE, EffectTiming.STATIC, EffectTiming.TRIGGERED
]
const _ACTION_TIMINGS: Array[EffectTiming] = [EffectTiming.RESOLVE, EffectTiming.TRIGGERED]

var kind: EffectKind = EffectKind.MODIFY_FORCE
var timing: EffectTiming = EffectTiming.RESOLVE
var trigger: TriggerEvent = TriggerEvent.NONE
var scope: StaticScope = StaticScope.NONE
## 207.3.5 : mention « une fois par tour », pour un effet déclenché seulement.
var once_per_turn: bool = false
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
var token_piece_kind: Piece.PieceKind = NO_TOKEN_KIND
var token_force: int = NO_TOKEN_FORCE
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Nom du `kind` tel que `ActiveEffect.effect_kind` le conserve : « modify_force ».
static func kind_id(effect_kind: EffectKind) -> StringName:
	return StringName(str(EffectKind.find_key(effect_kind)).to_lower())


## 207.3.5, 207.3.7 : la mention « une fois par tour » est portée par la carte et décomptée par
## carte ; le ruleset ne dit rien d'une carte à plusieurs effets déclenchés, qui est refusée.
## Message d'erreur sur les effets `effects` d'une carte ou d'un Hero, vide s'il n'y en a pas.
static func once_per_turn_error(effects: Array[EffectDefinition]) -> String:
	var triggered := effects.filter(
		func(effect: EffectDefinition) -> bool: return effect.timing == EffectTiming.TRIGGERED
	)
	var marked := triggered.any(func(effect: EffectDefinition) -> bool: return effect.once_per_turn)
	if marked and triggered.size() > 1:
		return "207.3.5 : « une fois par tour » exige un seul effet déclenché sur la carte"
	return ""


## Lit un effet depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> EffectDefinition:
	var effect := EffectDefinition.new()
	var reader := CatalogReader.new(data)
	reader.require("kind", "207")
	reader.require("timing", "207")
	var kind_value := reader.read_enum("kind", EffectKind)
	if kind_value != CatalogReader.NOT_SET:
		effect.kind = kind_value as EffectKind
	var timing_value := reader.read_enum("timing", EffectTiming)
	if timing_value != CatalogReader.NOT_SET:
		effect.timing = timing_value as EffectTiming
	effect._read_conditions(reader)
	effect._read_parameters(reader)
	effect.parse_errors = reader.finish()
	return effect


# 207.2.1, 207.3.1, 207.4.10, 207.5.1 : chaque timing exige ou interdit déclencheur, portée,
# cible et durée ; chaque kind exige ses paramètres et la cible qui lui convient.
func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	_check_timing(errors)
	_check_conditions(errors)
	_check_duration(errors)
	_check_parameters(errors)
	if target != null:
		for message: String in target.find_errors():
			errors.append("cible : " + message)
	if destination != null:
		for message: String in destination.find_errors():
			errors.append("destination : " + message)
	return errors


func _read_conditions(reader: CatalogReader) -> void:
	var trigger_value := reader.read_enum("trigger", TriggerEvent)
	if trigger_value != CatalogReader.NOT_SET:
		trigger = trigger_value as TriggerEvent
	var scope_value := reader.read_enum("scope", StaticScope)
	if scope_value != CatalogReader.NOT_SET:
		scope = scope_value as StaticScope
	once_per_turn = reader.read_bool("once_per_turn", false)
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
	amount = reader.read_signed_int("amount", 0)
	var token_kind_value := reader.read_enum("token_piece_kind", Piece.PieceKind)
	if token_kind_value != CatalogReader.NOT_SET:
		token_piece_kind = token_kind_value as Piece.PieceKind
	token_force = reader.read_int("token_force", CatalogReader.NON_NEGATIVE_MINIMUM, NO_TOKEN_FORCE)


func _timings_for_kind() -> Array[EffectTiming]:
	if kind == EffectKind.MODIFY_FORCE:
		return _MODIFY_FORCE_TIMINGS
	return _ACTION_TIMINGS


func _check_timing(errors: PackedStringArray) -> void:
	if _timings_for_kind().has(timing):
		return
	var kind_name := String(kind_id(kind))
	var timing_name := str(EffectTiming.find_key(timing)).to_lower()
	if kind == EffectKind.CREATE_TOKEN and timing == EffectTiming.STATIC:
		errors.append("202.4.7 : un effet statique ne crée pas de jeton")
	else:
		errors.append("207 : %s n'admet pas le timing %s" % [kind_name, timing_name])


func _check_conditions(errors: PackedStringArray) -> void:
	if timing == EffectTiming.TRIGGERED and trigger == TriggerEvent.NONE:
		errors.append("207.3.1 : un effet déclenché nomme son événement dans trigger")
	if timing != EffectTiming.TRIGGERED and trigger != TriggerEvent.NONE:
		errors.append("207.3.1 : trigger ne vaut que pour un effet déclenché")
	if timing != EffectTiming.TRIGGERED and once_per_turn:
		errors.append("207.3.5 : once_per_turn ne vaut que pour un effet déclenché")
	if timing == EffectTiming.STATIC and scope == StaticScope.NONE:
		errors.append("207.2.2 : un effet statique nomme les pièces qu'il touche dans scope")
	if timing != EffectTiming.STATIC and scope != StaticScope.NONE:
		errors.append("207.2.1 : scope ne vaut que pour un effet statique")
	if timing == EffectTiming.STATIC and target != null:
		errors.append("207.5.1 : un effet statique ne cible pas")
	if timing == EffectTiming.STATIC and subject != EffectSubject.TARGETS:
		errors.append("0057 : un effet statique ne nomme pas de sujet")
	var needs_target := timing != EffectTiming.STATIC and subject == EffectSubject.TARGETS
	if needs_target and target == null:
		errors.append("207.5.1 : un effet qui passe par la pile nomme sa cible")
	if subject != EffectSubject.TARGETS and target != null:
		errors.append("0057 : un effet dont le sujet n'est pas TARGETS ne nomme pas de cible")
	_check_subject(errors)


# Décision 0057 : piocher, défausser et regarder touchent le joueur ; réveiller, ses cibles ou la
# pièce source, celle-ci seulement pour un effet déclenché (un Spell n'a pas de pièce, un Ordre a
# celle du Hero, qui n'est pas une Unit) ; les autres kinds ciblent.
func _check_subject(errors: PackedStringArray) -> void:
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
		EffectKind.WAKE:
			return [EffectSubject.TARGETS, EffectSubject.SOURCE_PIECE]
	return [EffectSubject.TARGETS]


func _check_duration(errors: PackedStringArray) -> void:
	if timing == EffectTiming.STATIC and has_duration:
		errors.append("207.4.10 : un effet statique n'a pas de durée")
	var needs_duration := timing != EffectTiming.STATIC and kind == EffectKind.MODIFY_FORCE
	if needs_duration and not has_duration:
		errors.append("207.4.2 : un effet de Force non statique porte une durée")
	if has_duration and kind != EffectKind.MODIFY_FORCE:
		errors.append("207.4.9 : sans durée, l'effet est ponctuel, duration est sans objet")


func _check_parameters(errors: PackedStringArray) -> void:
	_check_amount(errors)
	var creates_token := kind == EffectKind.CREATE_TOKEN
	if creates_token and token_piece_kind == NO_TOKEN_KIND:
		errors.append("202.4.8 : un jeton est une Unit ou un Building, token_piece_kind le dit")
	if creates_token and token_force == NO_TOKEN_FORCE:
		errors.append("202.4.9 : l'effet qui crée un jeton lui donne une Force, token_force")
	if not creates_token and (token_piece_kind != NO_TOKEN_KIND or token_force != NO_TOKEN_FORCE):
		errors.append("202.4.1 : token_piece_kind et token_force ne valent que pour CREATE_TOKEN")
	_check_target_what(errors)
	_check_hero_target(errors)
	_check_movement(errors)
	_check_wake(errors)


# 206.5.1 : MODIFY_FORCE exige un modificateur non nul ; 201.3.2, 212.1.7 : piocher et défausser
# exigent un nombre de cartes positif ; les autres kinds n'ont pas d'amount.
func _check_amount(errors: PackedStringArray) -> void:
	if kind in [EffectKind.DRAW_CARDS, EffectKind.DISCARD_CARDS]:
		if amount < 1:
			errors.append("212.1.7 : amount est le nombre de cartes, au moins 1")
	elif (kind == EffectKind.MODIFY_FORCE) == (amount == 0):
		errors.append("206.5.1 : amount est exigé non nul pour MODIFY_FORCE, absent sinon")


func _check_target_what(errors: PackedStringArray) -> void:
	if target == null:
		return
	var expected := _expected_target_what()
	if target.what != expected:
		var expected_name := str(TargetSpec.TargetWhat.find_key(expected)).to_lower()
		errors.append("%s : %s cible %s" % [_target_rule(), String(kind_id(kind)), expected_name])


# 202.3.9, 206.4.3 : ni la Force ni la destruction d'un Hero ne sont tranchées par le ruleset ;
# un effet de Force ou de destruction ne vise donc pas de Hero.
func _check_hero_target(errors: PackedStringArray) -> void:
	if target == null or not target.piece_kinds.has(Piece.PieceKind.HERO):
		return
	if kind in [EffectKind.MODIFY_FORCE, EffectKind.DESTROY]:
		errors.append("202.3.9 : %s ne vise pas de Hero" % String(kind_id(kind)))


# 214.1.3, 214.1.4, 215.1.1, 216.1.1, décision 0056 : les trois effets de mouvement ciblent des
# Units ; l'échange en cible deux alliées ; le déplacement nomme sa case de destination.
func _check_movement(errors: PackedStringArray) -> void:
	var is_movement := (
		kind in [EffectKind.SWAP_CELLS, EffectKind.MOVE_UNIT, EffectKind.RETURN_TO_HAND]
	)
	if destination != null and kind != EffectKind.MOVE_UNIT:
		errors.append("215.1.1 : destination ne vaut que pour MOVE_UNIT")
	if target != null and target.adjacent_to == TargetSpec.AdjacentTo.TARGET_PIECE:
		errors.append("215.1.1 : target_piece ne vaut que pour la destination")
	if not is_movement or target == null:
		return
	var rule := _target_rule()
	if target.what == TargetSpec.TargetWhat.PIECE and target.piece_kinds != [Piece.PieceKind.UNIT]:
		errors.append("%s : %s ne cible que des Units" % [rule, String(kind_id(kind))])
	if kind == EffectKind.SWAP_CELLS:
		_check_swap(errors)
	if kind == EffectKind.MOVE_UNIT:
		_check_move(errors)


# Glossaire (Réveiller), 205.5.1, 205.5.2, 205.5.6 : un effet réveille une Unit ou un Hero, jamais
# un Building, qui n'est ni endormi ni éveillé ; `piece_kinds` le dit.
func _check_wake(errors: PackedStringArray) -> void:
	if kind != EffectKind.WAKE or target == null or target.what != TargetSpec.TargetWhat.PIECE:
		return
	var wakeable := not target.piece_kinds.is_empty()
	for piece_kind: Piece.PieceKind in target.piece_kinds:
		wakeable = wakeable and piece_kind != Piece.PieceKind.BUILDING
	if not wakeable:
		errors.append("205.5.6 : wake ne cible que des Units ou des Heroes, nommés par piece_kinds")


# 214.1.3, 214.1.4 : exactement deux Units alliées.
func _check_swap(errors: PackedStringArray) -> void:
	if target.side != TargetSpec.TargetSide.ALLY:
		errors.append("214.1.3 : swap_cells ne cible que des Units alliées")
	if target.count_min != SWAP_TARGET_COUNT or target.count_max != SWAP_TARGET_COUNT:
		errors.append("214.1.4 : swap_cells cible exactement deux Units")


# 215.1.1 : une Unit et une case libre.
func _check_move(errors: PackedStringArray) -> void:
	if target.count_min != MOVE_TARGET_COUNT or target.count_max != MOVE_TARGET_COUNT:
		errors.append("215.1.1 : move_unit cible une seule Unit")
	if destination == null:
		errors.append("215.1.1 : move_unit nomme sa case de destination dans destination")
		return
	if destination.what != TargetSpec.TargetWhat.CELL:
		errors.append("215.1.1 : la destination de move_unit est une case")
	if destination.count_min != MOVE_TARGET_COUNT or destination.count_max != MOVE_TARGET_COUNT:
		errors.append("215.1.1 : move_unit a une seule case de destination")


func _target_rule() -> String:
	match kind:
		EffectKind.SWAP_CELLS:
			return "214.1.4"
		EffectKind.MOVE_UNIT:
			return "215.1.1"
		EffectKind.RETURN_TO_HAND:
			return "216.1.1"
		EffectKind.COUNTER_SPELL:
			return "207.6.2"
		EffectKind.CREATE_TOKEN:
			return "202.4.12"
	return "207.5.11"


func _expected_target_what() -> TargetSpec.TargetWhat:
	match kind:
		EffectKind.COUNTER_SPELL:
			return TargetSpec.TargetWhat.SPELL_ON_STACK  # 207.6.2
		EffectKind.CREATE_TOKEN:
			return TargetSpec.TargetWhat.CELL  # 202.4.12
	return TargetSpec.TargetWhat.PIECE
