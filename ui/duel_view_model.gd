class_name DuelViewModel
extends RefCounted
## Ce que le joueur qui a l'appareil peut voir du duel (201.4 ; décision 0030) : le moteur est
## omniscient, la vue filtre. Sa main en cartes ; la main adverse en nombre seulement ; les decks
## en nombre ; les défausses en cartes (201.4.3) ; la pile (201.4.7). Une carte cachée (main
## adverse, deck, Écart) n'est jamais rendue : `visible_definition` rend null pour elle.
##
## Rassemble aussi les valeurs que l'écran dérive de l'état sans règle propre (Sources et Essence
## montrées, état du centre de la colonne, lignes de la pile), en fonctions pures testables sans
## scène. L'objet lit l'état en direct ; l'écran en refait un à chaque recalage.

## Forme d'une pièce du plateau : elle décide comment l'écran la remplit et l'aperçoit.
enum PieceForm {
	HERO,
	TOKEN,
	CARD,
}

const TOKEN_CARD_TYPES: Dictionary[Piece.PieceKind, CardDefinition.CardType] = {
	Piece.PieceKind.UNIT: CardDefinition.CardType.UNIT,
	Piece.PieceKind.BUILDING: CardDefinition.CardType.BUILDING,
}
const NORMAL_ACTION_LABEL: String = "Action normale"
const PENDING_COMBAT_LABEL: String = "Combat"
const TRIGGERED_EFFECT_LABEL: String = "Effet déclenché"
const TRIGGERED_EFFECT_FORMAT: String = "Effet : %s"
const ACTION_HELP_KIND: String = "Action"
const HELP_FORMAT: String = "%s · %s"
const ORDER_INSTRUCTION: String = "Ordre des effets : clique-les dans l'ordre d'ajout à la pile"
const TARGET_INSTRUCTION: String = "Choisis la cible de l'effet"
const DISCARD_INSTRUCTION_FORMAT: String = "Défausse %d carte(s) : clique-les dans ta main"
const LOOK_INSTRUCTION: String = "Carte du dessus de ton deck : garde-la dessus ou mets-la dessous"
const WAITING_CHOICE_INSTRUCTION: String = "Choix en cours"
const ORDER_LABEL: String = "Ordre"
const X_HELP_FORMAT: String = "%s · X = %d"
const ENDED_TEXT: String = "Duel terminé"
const RESULT_TEXTS: Dictionary[DuelState.DuelResult, String] = {
	DuelState.DuelResult.NONE: ENDED_TEXT,
	DuelState.DuelResult.PLAYER_A_WINS: "Victoire du joueur A",
	DuelState.DuelResult.PLAYER_B_WINS: "Victoire du joueur B",
	DuelState.DuelResult.DRAW: "Égalité",
}

var _state: DuelState
var _catalog: Catalog
var _viewer: DuelState.PlayerSide


## `viewer` est le joueur qui a l'appareil (DuelHost.get_screen_player).
func _init(state: DuelState, catalog: Catalog, viewer: DuelState.PlayerSide) -> void:
	_state = state
	_catalog = catalog
	_viewer = viewer


## État du centre de la colonne : la fin l'emporte, puis un choix attendu du moteur (le mulligan
## ou un autre), puis la pile non vide, sinon le tour. Pur.
static func center_state_of(state: DuelState) -> DuelColumnView.CenterState:
	if state.is_ended():
		return DuelColumnView.CenterState.ENDED
	var decision := state.pending_decision
	if decision != null:
		if decision.kind == PendingDecision.DecisionKind.MULLIGAN:
			return DuelColumnView.CenterState.MULLIGAN
		return DuelColumnView.CenterState.CHOICE
	if not state.stack.is_empty():
		return DuelColumnView.CenterState.STACK
	return DuelColumnView.CenterState.TURN


## Consigne d'un choix demandé par le moteur (hors mulligan, que la colonne annonce elle-même) ;
## `required_count` est le nombre de cartes à défausser (212.1.7).
static func choice_instruction(
	kind: PendingDecision.DecisionKind, required_count: int = 0
) -> String:
	match kind:
		PendingDecision.DecisionKind.ORDER_TRIGGERS:
			return ORDER_INSTRUCTION
		PendingDecision.DecisionKind.CHOOSE_DISCARD:
			return DISCARD_INSTRUCTION_FORMAT % required_count
		PendingDecision.DecisionKind.CHOOSE_TOP_CARD_PLACE:
			return LOOK_INSTRUCTION
	return TARGET_INSTRUCTION


## Ligne de résultat d'un duel terminé.
static func result_text(result: DuelState.DuelResult) -> String:
	return RESULT_TEXTS[result]


## Forme de `piece`.
static func piece_form_of(piece: Piece) -> PieceForm:
	if piece.kind == Piece.PieceKind.HERO:
		return PieceForm.HERO
	return PieceForm.TOKEN if piece.is_token() else PieceForm.CARD


## 201.4.11, 205.5.6 : une Unit ou un Hero endormi est montré endormi, aux deux joueurs ; un
## Building n'est ni endormi ni éveillé.
static func is_shown_asleep(piece: Piece) -> bool:
	return piece.is_asleep()


## Joueur dont le choix `decision` s'affiche : celui qui a l'appareil s'il est attendu, sinon le
## premier joueur attendu.
func chooser_of(decision: PendingDecision) -> DuelState.PlayerSide:
	if decision.awaited_players.has(_viewer):
		return _viewer
	return decision.awaited_players[0]


func get_viewer() -> DuelState.PlayerSide:
	return _viewer


## L'autre joueur, dont la main est cachée.
func get_opponent() -> DuelState.PlayerSide:
	return DuelState.opponent_of(_viewer)


## Cartes de la main du joueur qui a l'appareil, dans l'ordre de la main.
func hand_cards() -> Array[HandView.HandCard]:
	var cards: Array[HandView.HandCard] = []
	for card: CardInstance in _state.get_player(_viewer).hand:
		cards.append(_to_hand_card(card))
	return cards


## 201.4.2 : la main adverse n'est connue que par son nombre de cartes.
func opponent_hand_size() -> int:
	return _state.get_player(get_opponent()).hand.size()


## 201.4.1 : un deck n'est connu que par son nombre de cartes.
func deck_size(side: DuelState.PlayerSide) -> int:
	return _state.get_player(side).deck.size()


## 209.5 : fatigue de `side`.
func fatigue(side: DuelState.PlayerSide) -> int:
	return _state.get_player(side).fatigue_counter


## 201.4.3 : carte du dessus de la défausse de `side`, ou null si elle est vide.
func discard_top(side: DuelState.PlayerSide) -> HandView.HandCard:
	var discard := _state.get_player(side).discard
	if discard.is_empty():
		return null
	var top: CardInstance = discard.back()
	return _to_hand_card(top)


## Définition de la carte `card_instance_id` si le joueur qui a l'appareil peut la voir (sa main,
## une défausse, la carte du dessus de son deck qu'il regarde, 201.4.1a), sinon null : une carte
## adverse en main, en deck ou à l'Écart reste cachée.
func visible_definition(card_instance_id: int) -> CardDefinition:
	var looked := _looked_card()
	if looked != null and looked.card_instance_id == card_instance_id:
		return _catalog.get_card(looked.definition_id)
	var own_hand := _state.get_player(_viewer).hand
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var visible_cards: Array[CardInstance] = _state.get_player(side).discard.duplicate()
		if side == _viewer:
			visible_cards.append_array(own_hand)
		for card: CardInstance in visible_cards:
			if card.card_instance_id == card_instance_id:
				return _catalog.get_card(card.definition_id)
	return null


## 203.6, décision 0032 : pendant son tour, la réserve d'Essence réelle de `side` ; pendant le tour
## adverse, le paiement préparé de celui qui a l'appareil ; l'autre bloc montre sa réserve réelle.
func essence_shown(side: DuelState.PlayerSide, shown: SelectionSnapshot) -> int:
	if side == _viewer and shown.is_drafting_payment:
		return shown.draft_payment.essence_produced()
	return _state.get_player(side).essence_reserve


## Sources redressées de `side` : celles de `shown` pour le joueur qui a l'appareil (paiement
## préparé déduit), sinon celles de l'état.
func upright_sources(side: DuelState.PlayerSide, shown: SelectionSnapshot) -> int:
	if side == _viewer:
		return shown.shown_upright_sources
	return _state.get_player(side).sources_upright


## Sources inclinées de `side`, comme `upright_sources`.
func tilted_sources(side: DuelState.PlayerSide, shown: SelectionSnapshot) -> int:
	if side == _viewer:
		return shown.shown_tilted_sources
	return _state.get_player(side).sources_tilted


## 201.4.5 : Sources de la réserve de `side`, visibles des deux joueurs.
func reserve_sources(side: DuelState.PlayerSide) -> int:
	return _state.get_player(side).sources_in_reserve


## 201.4.6 : Sources de la Fonte de `side`, visibles des deux joueurs ; celles de `shown` pour le
## joueur qui a l'appareil (paiement préparé compris, 203.5.3), sinon celles de l'état.
func fonte_sources(side: DuelState.PlayerSide, shown: SelectionSnapshot) -> int:
	if side == _viewer:
		return shown.shown_fonte_sources
	return _state.get_player(side).sources_in_fonte


## Définition du Hero de `side`, d'après sa pièce.
func hero_definition(side: DuelState.PlayerSide) -> HeroDefinition:
	return _catalog.get_hero(_state.find_hero(side).card.definition_id)


## Définition de la carte d'une Unit ou d'un Building de carte ; null pour un Hero ou un jeton.
func piece_definition(piece: Piece) -> CardDefinition:
	if piece_form_of(piece) != PieceForm.CARD:
		return null
	return _catalog.get_card(piece.card.definition_id)


## Type de carte d'un jeton (202.4) : celui de sa pièce.
static func token_card_type(piece: Piece) -> CardDefinition.CardType:
	return TOKEN_CARD_TYPES[piece.kind]


## Gear attaché à `piece` (202.2.10), ou null.
func gear_definition(piece: Piece) -> CardDefinition:
	if piece.attached_gear == null:
		return null
	return _catalog.get_card(piece.attached_gear.definition_id)


## Lignes de la pile (201.4.7), de la base au sommet, l'entrée dont la résolution attend un choix
## (décision 0057) au sommet. Les effets déclenchés en attente de
## `extra_entry_ids` s'ajoutent au sommet (ordre à choisir) ; le rang d'une entrée de `ordered_ids`
## est son indice + 1, NO_ORDER si elle n'y est pas.
func stack_lines(
	extra_entry_ids: Array[int] = [], ordered_ids: Array[int] = []
) -> Array[StackView.StackLine]:
	var entries: Array[StackEntry] = _state.stack.duplicate()
	if _state.resolving_entry != null:
		entries.append(_state.resolving_entry)
	for entry: StackEntry in _state.waiting_triggers:
		if extra_entry_ids.has(entry.stack_entry_id):
			entries.append(entry)
	var lines: Array[StackView.StackLine] = []
	for entry: StackEntry in entries:
		var line := _stack_line(entry)
		var index := ordered_ids.find(entry.stack_entry_id)
		line.order_number = StackView.NO_ORDER if index < 0 else index + 1
		lines.append(line)
	return lines


## Carte que montre l'aperçu d'une entrée de pile : celle qu'elle annonce, ou la carte source d'un
## effet déclenché ; null sans carte (action normale, Ordre du Hero : `order_hero`).
func entry_definition(entry: StackEntry) -> CardDefinition:
	if entry.kind == StackEntry.StackEntryKind.ORDER:
		return null
	if entry.card != null:
		return _catalog.get_card(entry.card.definition_id)
	if _catalog.has_definition(entry.source_definition_id):
		return _catalog.get_card(entry.source_definition_id)
	return null


## 217.1.1 : carte du dessus du deck que `side` regarde dans `state` (le moteur attend son choix de
## place), sinon NO_ID.
static func looked_card_id(state: DuelState, side: DuelState.PlayerSide) -> int:
	var decision := state.pending_decision
	var kind := PendingDecision.DecisionKind.CHOOSE_TOP_CARD_PLACE
	if decision == null or decision.kind != kind or not decision.awaited_players.has(side):
		return DuelState.NO_ID
	return decision.candidate_ids[0]


## Entrée `stack_entry_id` de la pile ou des effets déclenchés en attente, ou null.
func find_entry(stack_entry_id: int) -> StackEntry:
	var entry := _state.find_stack_entry(stack_entry_id)
	if entry != null:
		return entry
	for waiting: StackEntry in _state.waiting_triggers:
		if waiting.stack_entry_id == stack_entry_id:
			return waiting
	return null


# 217.1.1, 201.4.1a : la carte du dessus que le joueur de l'appareil regarde ; null sinon.
func _looked_card() -> CardInstance:
	var looked_id := looked_card_id(_state, _viewer)
	for card: CardInstance in _state.get_player(_viewer).deck:
		if card.card_instance_id == looked_id:
			return card
	return null


func _to_hand_card(card: CardInstance) -> HandView.HandCard:
	return HandView.HandCard.new(card.card_instance_id, _catalog.get_card(card.definition_id))


func _stack_line(entry: StackEntry) -> StackView.StackLine:
	var definition := entry_definition(entry)
	var line := StackView.StackLine.new(
		entry.stack_entry_id,
		_stack_label(entry, definition),
		_stack_tint(entry, definition),
		entry.owner
	)
	var help := HELP_FORMAT % [_stack_help_kind(entry, definition), _owner_name(entry)]
	if entry.x_value > 0:
		help = X_HELP_FORMAT % [help, entry.x_value]
	return line.with_help(help)


# Le type de la carte annoncée, ou le genre de l'entrée quand elle n'en a pas.
func _stack_help_kind(entry: StackEntry, definition: CardDefinition) -> String:
	match entry.kind:
		StackEntry.StackEntryKind.NORMAL_ACTION:
			return ACTION_HELP_KIND
		StackEntry.StackEntryKind.PENDING_COMBAT:
			return PENDING_COMBAT_LABEL
		StackEntry.StackEntryKind.TRIGGERED_EFFECT:
			return TRIGGERED_EFFECT_LABEL
		StackEntry.StackEntryKind.ORDER:
			return ORDER_LABEL
	return CardText.type_name(definition.card_type)


# Le Hero qui porte l'Ordre d'une entrée ORDER (211.2.8).
func _order_hero(entry: StackEntry) -> HeroDefinition:
	return _catalog.get_hero(entry.source_definition_id)


func _owner_name(entry: StackEntry) -> String:
	return PlayerNames.display_name(entry.owner)


func _stack_label(entry: StackEntry, definition: CardDefinition) -> String:
	match entry.kind:
		StackEntry.StackEntryKind.NORMAL_ACTION:
			return NORMAL_ACTION_LABEL
		StackEntry.StackEntryKind.PENDING_COMBAT:
			return PENDING_COMBAT_LABEL
		StackEntry.StackEntryKind.TRIGGERED_EFFECT:
			return _triggered_label(definition)
		StackEntry.StackEntryKind.ORDER:
			return _order_hero(entry).hero_name
	return definition.card_name


func _triggered_label(definition: CardDefinition) -> String:
	if definition == null:
		return TRIGGERED_EFFECT_LABEL
	return TRIGGERED_EFFECT_FORMAT % definition.card_name


# La teinte de la carte annoncée ; celle d'un Spell à défaut.
func _stack_tint(entry: StackEntry, definition: CardDefinition) -> DuelPalette.Tint:
	if entry.kind == StackEntry.StackEntryKind.ORDER:
		return DuelPalette.Tint.HERO
	if definition == null:
		return DuelPalette.Tint.SPELL
	return DuelPalette.tint_of(definition.card_type)
