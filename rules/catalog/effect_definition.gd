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
}

## Quand l'effet a lieu.
enum EffectTiming {
	RESOLVE,  # à la résolution de l'entrée de la pile qui le porte (Spell, pouvoir du Hero)
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

## Valeur de `token_force` quand l'effet ne crée pas de jeton.
const NO_TOKEN_FORCE: int = -1
## `token_piece_kind` non renseigné : un jeton n'est jamais un Hero (202.4.8).
const NO_TOKEN_KIND: Piece.PieceKind = Piece.PieceKind.HERO
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
## Null pour un effet statique, qui ne cible pas (207.2.1).
var target: TargetSpec
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
	return errors


func _read_conditions(reader: CatalogReader) -> void:
	var trigger_value := reader.read_enum("trigger", TriggerEvent)
	if trigger_value != CatalogReader.NOT_SET:
		trigger = trigger_value as TriggerEvent
	var scope_value := reader.read_enum("scope", StaticScope)
	if scope_value != CatalogReader.NOT_SET:
		scope = scope_value as StaticScope
	once_per_turn = reader.read_bool("once_per_turn", false)
	if reader.has("target"):
		target = TargetSpec.from_dict(reader.read_object("target"))


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
	if timing != EffectTiming.STATIC and target == null:
		errors.append("207.5.1 : un effet qui passe par la pile nomme sa cible")


func _check_duration(errors: PackedStringArray) -> void:
	if timing == EffectTiming.STATIC and has_duration:
		errors.append("207.4.10 : un effet statique n'a pas de durée")
	var needs_duration := timing != EffectTiming.STATIC and kind == EffectKind.MODIFY_FORCE
	if needs_duration and not has_duration:
		errors.append("207.4.2 : un effet de Force non statique porte une durée")
	if has_duration and kind != EffectKind.MODIFY_FORCE:
		errors.append("207.4.9 : sans durée, l'effet est ponctuel, duration est sans objet")


func _check_parameters(errors: PackedStringArray) -> void:
	if (kind == EffectKind.MODIFY_FORCE) == (amount == 0):
		errors.append("206.5.1 : amount est exigé non nul pour MODIFY_FORCE, absent sinon")
	var creates_token := kind == EffectKind.CREATE_TOKEN
	if creates_token and token_piece_kind == NO_TOKEN_KIND:
		errors.append("202.4.8 : un jeton est une Unit ou un Building, token_piece_kind le dit")
	if creates_token and token_force == NO_TOKEN_FORCE:
		errors.append("202.4.9 : l'effet qui crée un jeton lui donne une Force, token_force")
	if not creates_token and (token_piece_kind != NO_TOKEN_KIND or token_force != NO_TOKEN_FORCE):
		errors.append("202.4.1 : token_piece_kind et token_force ne valent que pour CREATE_TOKEN")
	_check_target_what(errors)
	_check_hero_target(errors)


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


func _target_rule() -> String:
	match kind:
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
