extends GdUnitTestSuite
## DuelState.clone() : copie de chaque champ, indépendance, compteurs et RNG
## (décisions 0001, 0004, 0008 et 0009 ; ruleset 0.28).

const STATE_CLASSES: Array[String] = [
	"DuelState",
	"PlayerState",
	"CardInstance",
	"Piece",
	"StackEntry",
	"ActiveEffect",
	"PendingDecision",
]
const DRAW_COUNT: int = 5
const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const UNIT_ID: StringName = &"UNIT"
const SPELL_ID: StringName = &"SPELL"
const GEAR_ID: StringName = &"GEAR"
const BUILDING_ID: StringName = &"BUILDING"


## Garde-fou des tests suivants : un champ resté à sa valeur par défaut partout ne prouverait
## pas sa copie. Un champ ajouté sans être renseigné par _build_full_state() échoue ici.
func test_full_state_sets_every_field_of_every_state_class() -> void:
	var state := _build_full_state()
	assert_array(DeepCompare.find_reached_classes(state)).contains_exactly_in_any_order(
		STATE_CLASSES
	)
	assert_array(DeepCompare.find_fields_never_set(state)).is_empty()


func test_clone_copies_every_field() -> void:
	var state := _build_full_state()
	assert_array(DeepCompare.find_clone_defects(state, state.clone())).is_empty()


func test_clone_shares_only_the_read_only_config() -> void:
	var state := _build_full_state()
	var copy := state.clone()
	assert_object(copy.config).is_same(state.config)
	assert_object(copy.rng).is_not_same(state.rng)
	assert_object(copy.pieces[0]).is_not_same(state.pieces[0])
	assert_object(copy.pieces[0].card).is_not_same(state.pieces[0].card)
	assert_object(copy.pending_decision).is_not_same(state.pending_decision)
	assert_object(copy.get_player(A).hand[0]).is_not_same(state.get_player(A).hand[0])


func test_clone_of_fresh_state_keeps_absent_decision_and_cards() -> void:
	var state := DuelState.create(DuelConfig.new())
	var copy := state.clone()
	assert_array(DeepCompare.find_clone_defects(state, copy)).is_empty()
	assert_object(copy.pending_decision).is_null()
	assert_array(copy.players).has_size(DuelState.PLAYER_COUNT)


func test_mutating_clone_leaves_original_unchanged() -> void:
	var state := _build_full_state()
	var snapshot := state.clone()
	var copy := state.clone()
	var player := copy.get_player(A)
	player.sources_upright += 3
	player.fatigue_counter += 1
	player.hand[0].card_instance_id = 999
	player.deck.pop_back()
	player.set_aside.clear()
	copy.pieces[0].cell = DuelStateBuilder.cell("D4")
	copy.pieces[0].card.owner = B
	_mutate_unit_and_token(copy)
	copy.stack[0].target_cells.append(DuelStateBuilder.cell("D3"))
	copy.stack[0].target_piece_ids.clear()
	copy.stack.pop_back()
	copy.active_effects[0].amount += 1
	copy.pending_decision.awaited_players.clear()
	copy.pending_decision.candidate_ids.append(77)
	copy.allocate_card_instance_id()
	copy.allocate_piece_id()
	copy.allocate_stack_entry_id()
	copy.allocate_active_effect_id()
	assert_array(DeepCompare.find_clone_defects(snapshot, state)).is_empty()


func test_clone_counters_continue_identically() -> void:
	var state := _build_full_state()
	var copy := state.clone()
	assert_int(copy.allocate_card_instance_id()).is_equal(state.allocate_card_instance_id())
	assert_int(copy.allocate_piece_id()).is_equal(state.allocate_piece_id())
	assert_int(copy.allocate_stack_entry_id()).is_equal(state.allocate_stack_entry_id())
	assert_int(copy.allocate_active_effect_id()).is_equal(state.allocate_active_effect_id())


func test_ids_are_never_reused() -> void:
	var state := DuelState.create(DuelConfig.new())
	var first := state.allocate_piece_id()
	var second := state.allocate_piece_id()
	assert_int(first).is_equal(DuelState.FIRST_ID)
	assert_int(second).is_equal(first + 1)
	assert_int(first).is_not_equal(DuelState.NO_ID)


func test_clone_rng_produces_same_sequence() -> void:
	var state := _build_full_state()
	var copy := state.clone()
	assert_int(copy.rng.seed).is_equal(state.rng.seed)
	assert_int(copy.rng.state).is_equal(state.rng.state)
	assert_array(_draw(copy.rng)).is_equal(_draw(state.rng))


func test_drawing_in_clone_does_not_change_original_rng() -> void:
	var state := _build_full_state()
	var state_before := state.rng.state
	var copy := state.clone()
	_draw(copy.rng)
	assert_int(state.rng.state).is_equal(state_before)


## Vérifie l'outil lui-même : un champ oublié et un objet partagé sont détectés.
func test_deep_compare_detects_missing_field_and_shared_object() -> void:
	var state := _build_full_state()
	var missing_field := state.clone()
	missing_field.consecutive_passes = 0
	assert_array(DeepCompare.find_clone_defects(state, missing_field)).is_not_empty()
	var shared_player := state.clone()
	shared_player.players[0] = state.players[0]
	assert_array(DeepCompare.find_clone_defects(state, shared_player)).is_not_empty()
	var missing_decision := state.clone()
	missing_decision.pending_decision = null
	assert_array(DeepCompare.find_clone_defects(state, missing_decision)).is_not_empty()


## Renseigne chaque champ de chaque classe d'état avec une valeur non par défaut.
func _build_full_state() -> DuelState:
	var builder := DuelStateBuilder.new()
	builder.with_seed(42)
	builder.with_phase(DuelState.DuelPhase.ENDED)
	builder.with_result(DuelState.DuelResult.DRAW)
	builder.with_first_player(B)
	builder.with_active_player(B)
	builder.with_priority_player(B)
	builder.with_turn_number(3)
	builder.with_consecutive_passes(1)
	for side: DuelState.PlayerSide in [A, B]:
		_fill_player(builder, side)
	var unit_id := builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), UNIT_ID
	)
	builder.place_piece(B, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("D4"), BUILDING_ID)
	var token_id := builder.place_token(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("E3"), 2)
	builder.attach_gear(unit_id, GEAR_ID)
	builder.add_active_effect(_make_effect(unit_id))
	var spell_card := builder.make_card_instance(A, SPELL_ID)
	var spell_entry_id := builder.push_spell(spell_card, [unit_id, token_id])
	builder.push_stack_entry(_make_trigger(builder, token_id, spell_entry_id))
	builder.with_pending_decision(_make_decision(spell_entry_id, unit_id))
	var state := builder.build()
	_draw(state.rng)
	return state


func _fill_player(builder: DuelStateBuilder, side: DuelState.PlayerSide) -> void:
	builder.with_hero_health(side, 12)
	builder.with_clock_remaining(side, 90_000)
	builder.with_fatigue(side, 2)
	builder.with_sources_in_reserve(side, 5)
	builder.with_sources_in_play(side, 2, 1)
	builder.with_sources_in_fonte(side, 2)
	builder.with_recycled_this_turn(side, 1)
	builder.with_hero_power_used(side)
	builder.with_normal_action_used(side)
	builder.add_to_deck(side, UNIT_ID)
	builder.add_to_deck(side, SPELL_ID)
	builder.add_to_hand(side, UNIT_ID)
	builder.add_to_discard(side, SPELL_ID)
	builder.add_to_set_aside(side, GEAR_ID)


func _make_effect(piece_id: int) -> ActiveEffect:
	var effect := ActiveEffect.new()
	effect.duration = ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY
	effect.owner = B
	effect.source_card_instance_id = 5
	effect.affected_piece_id = piece_id
	effect.effect_kind = &"force_modifier"
	effect.amount = 2
	return effect


func _make_trigger(
	builder: DuelStateBuilder, source_piece_id: int, target_entry_id: int
) -> StackEntry:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.TRIGGERED_EFFECT
	entry.owner = B
	entry.card = builder.make_card_instance(B, UNIT_ID)
	entry.source_piece_id = source_piece_id
	entry.effect_index = 1
	entry.target_cells.append(DuelStateBuilder.cell("C3"))
	entry.target_piece_ids.append(source_piece_id)
	entry.target_stack_entry_ids.append(target_entry_id)
	return entry


func _make_decision(entry_id: int, piece_id: int) -> PendingDecision:
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.CHOOSE_TARGETS
	decision.awaited_players.append(B)
	decision.subject_stack_entry_id = entry_id
	decision.candidate_ids.append(piece_id)
	decision.candidate_cells.append(DuelStateBuilder.cell("A3"))
	return decision


func _mutate_unit_and_token(copy: DuelState) -> void:
	for piece: Piece in copy.pieces:
		if piece.attached_gear != null:
			piece.attached_gear.card_instance_id = 888
		if piece.is_token():
			piece.token_force += 1
		else:
			piece.health += 1


func _draw(rng: RandomNumberGenerator) -> Array[int]:
	var values: Array[int] = []
	for index: int in DRAW_COUNT:
		values.append(rng.randi())
	return values
