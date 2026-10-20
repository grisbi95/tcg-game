class_name ResponseWindowSamples
extends RefCounted
## Catalogues et mains d'essai pour les fenêtres de réponse de `DuelHost` (208.6).


## Un Spell de vitesse Réaction sans effet ni cible, payable au tour adverse (208.2.3).
static func catalog_with_reaction(reaction_id: StringName) -> Catalog:
	var data := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(reaction_id))
	data = CatalogSamples.with_field(data, "effects", [])
	data = CatalogSamples.with_field(data, "text", "")
	var catalog := SetupSamples.catalog()
	catalog.add_card(CardDefinition.from_dict(data))
	return catalog


## 207.5.1b : le Héraut, à l'arrivée, fait choisir sa cible parmi plusieurs Units ennemies.
static func catalog_with_herald() -> Catalog:
	var catalog := SetupSamples.catalog()
	for data: Dictionary in TriggerSamples.card_data():
		if data["id"] == String(TriggerSamples.HERALD):
			catalog.add_card(CardDefinition.from_dict(data))
	return catalog


## Place une carte dans la main d'un duel déjà démarré, comme DuelStateBuilder.place_unit_in.
static func add_to_hand(
	state: DuelState, side: DuelState.PlayerSide, definition_id: StringName
) -> CardInstance:
	var card := CardInstance.new()
	card.card_instance_id = state.allocate_card_instance_id()
	card.definition_id = definition_id
	card.owner = side
	state.get_player(side).hand.append(card)
	return card


## Le temps écoulé s'inscrit aussi au journal : seules les intentions comptent ici.
static func journaled_intent_count(host: DuelHost) -> int:
	var count := 0
	for entry: DuelJournal.Entry in host.get_journal().entries:
		if not entry.is_elapsed_time():
			count += 1
	return count


## Les deux mulligans sans carte écartée, de A puis de B, relais compris (décisions 0013 et 0015).
static func accept_mulligans(host: DuelHost) -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		host.submit_human(ChooseMulligan.new(side))
		host.confirm_events_played()
		host.confirm_relay()


## 208.2.4 : A annonce `card` sur la première case où le moteur l'accepte ; faux si aucune.
static func try_deploy(host: DuelHost, engine: DuelEngine, card: CardInstance, cost: int) -> bool:
	var side := DuelState.PlayerSide.A
	var payment := EssencePayment.new(cost, 0)
	for cell: Vector2i in BoardGeometry.all_cells():
		var intent := DeployCard.new(side, card.card_instance_id, cell, payment)
		if engine.validate(intent) == IntentRejected.RejectReason.NONE:
			host.submit_human(intent)
			return true
	return false
