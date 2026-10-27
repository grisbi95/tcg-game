class_name Catalog
extends RefCounted
## Ensemble des définitions chargées : cartes de deck et Heroes (décisions 0002 et 0010).
##
## `CardInstance.definition_id` se résout ici (décision 0008). Les cartes et les Heroes partagent
## un seul espace d'identifiants, le Hero étant une carte (202.3.4).

var edition: String = ""
var _cards: Dictionary[StringName, CardDefinition] = {}
var _heroes: Dictionary[StringName, HeroDefinition] = {}
var _card_order: Array[CardDefinition] = []
var _hero_order: Array[HeroDefinition] = []
var _build_errors: PackedStringArray = PackedStringArray()


## Ajoute une carte ; un identifiant déjà pris est une erreur et la carte n'est pas résolue.
func add_card(card: CardDefinition) -> void:
	_card_order.append(card)
	if has_definition(card.id):
		_build_errors.append("carte « %s » : id déjà pris" % card.id)
		return
	_cards[card.id] = card


func add_hero(hero: HeroDefinition) -> void:
	_hero_order.append(hero)
	if has_definition(hero.id):
		_build_errors.append("hero « %s » : id déjà pris" % hero.id)
		return
	_heroes[hero.id] = hero


## Null si `id` n'est pas une carte de deck.
func get_card(id: StringName) -> CardDefinition:
	return _cards.get(id)


## Null si `id` n'est pas un Hero.
func get_hero(id: StringName) -> HeroDefinition:
	return _heroes.get(id)


## 207.3.3, 202.3.20, décision 0064 : liste de textes que `StackEntry.text_index` indexe pour un
## effet déclenché de `id` : les textes de la carte, ou les textes déclenchés du Hero. Vide si `id`
## est inconnu.
func triggerable_texts(id: StringName) -> Array[EffectText]:
	var hero := get_hero(id)
	if hero != null:
		return hero.triggered
	var card := get_card(id)
	if card != null:
		return card.texts
	return []


func has_definition(id: StringName) -> bool:
	return _cards.has(id) or _heroes.has(id)


func card_count() -> int:
	return _card_order.size()


func hero_count() -> int:
	return _hero_order.size()


## Identifiants des cartes de deck, dans l'ordre d'ajout.
func card_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for card: CardDefinition in _card_order:
		ids.append(card.id)
	return ids


## Erreurs de chaque définition, préfixées par son identifiant, et identifiants dupliqués.
func find_errors() -> PackedStringArray:
	var errors := _build_errors.duplicate()
	for index: int in _card_order.size():
		for message: String in _card_order[index].find_errors():
			errors.append("carte %s : %s" % [_label(_card_order[index].id, index), message])
	for index: int in _hero_order.size():
		for message: String in _hero_order[index].find_errors():
			errors.append("hero %s : %s" % [_label(_hero_order[index].id, index), message])
	return errors


# 201.6.1, 201.6.2, 202.3.5 : un deck compte `deck_size` cartes de deck, au plus
# `max_copies_per_card` exemplaires (cartes de même nom) de chacune ; le Hero n'en fait pas
# partie. 201.6.3 : le Hero ne limite pas le deck, d'où l'absence de Hero en paramètre.
func find_deck_errors(deck: Array[StringName], config: DuelConfig) -> PackedStringArray:
	var errors := PackedStringArray()
	if deck.size() != config.deck_size:
		errors.append("201.6.1 : %d cartes au lieu de %d" % [deck.size(), config.deck_size])
	var copies_by_name: Dictionary[String, int] = {}
	for id: StringName in deck:
		var card := get_card(id)
		if card == null:
			errors.append("202.3.5 : « %s » n'est pas une carte de deck du catalogue" % id)
			continue
		copies_by_name[card.card_name] = copies_by_name.get(card.card_name, 0) + 1
	for card_name: String in copies_by_name:
		if copies_by_name[card_name] > config.max_copies_per_card:
			errors.append(
				(
					"201.6.2 : %d exemplaires de « %s », au plus %d"
					% [copies_by_name[card_name], card_name, config.max_copies_per_card]
				)
			)
	return errors


func _label(id: StringName, index: int) -> String:
	return "« %s »" % id if not String(id).is_empty() else "#%d" % (index + 1)
