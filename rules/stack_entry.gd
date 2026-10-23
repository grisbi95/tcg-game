class_name StackEntry
extends RefCounted
## Entrée de la pile : annonce ou effet déclenché en attente de résolution (208.1, 207.3.2).
##
## Un champ inutile pour un `kind` garde sa valeur par défaut (NO_ID, tableau vide, null).
## Le coût est payé à l'annonce (203.3.2) : l'entrée ne le porte pas.

## Enum journalisable : ajouter à la fin, sans réordonner.
enum StackEntryKind {
	DEPLOY,  # 208.1.1
	NORMAL_ACTION,  # 208.1.2
	SPELL,  # 208.1.3
	HERO_POWER,  # retiré en édition 0.42 (décision 0208)
	ATTACH_GEAR,  # 208.1.5
	TRIGGERED_EFFECT,  # 207.3.2
	PENDING_COMBAT,  # 205.6.1 : combat en attente, décision 0046
}

var stack_entry_id: int = DuelState.NO_ID
var kind: StackEntryKind = StackEntryKind.DEPLOY
## 208.2.4 : joueur à qui appartient l'entrée ; pour un effet déclenché, 207.3.4.
var owner: DuelState.PlayerSide = DuelState.PlayerSide.A
## Carte déployée, Spell joué ou Gear attaché ; null pour les autres genres. Un combat en attente
## porte la carte de l'Unit qui se déploie (205.6.8) et reste sans carte pour une action normale.
var card: CardInstance
## Pièce qui agit (action normale, 205.4.3) ou qui porte l'effet déclenché (207.3.3).
var source_piece_id: int = DuelState.NO_ID
## 207.3.3, 207.3.7 : pour un effet déclenché, carte qui le porte, lisible même après le départ
## de sa pièce du plateau ; NO_ID et vide pour les autres genres.
var source_card_instance_id: int = DuelState.NO_ID
var source_definition_id: StringName = &""
## 208.7 : faux pour une entrée sans réponse, posé à sa naissance (décision 0046). Aucun joueur ne
## peut répondre ni passer après son ajout, et la pile qui la contient se résout aussitôt
## (208.7.12, 208.7.13). Vrai par défaut : Spell, attaque, combat en attente (208.7.1, 208.7.2,
## 208.7.14).
var allows_response: bool = true
## Rang de l'effet dans la définition de la carte, pour un effet déclenché ou un Spell.
var effect_index: int = 0
## 205.1.5, 205.2.5, 207.5.11 : cases choisies à l'annonce (déploiement, action, cibles).
var target_cells: Array[Vector2i] = []
## 207.5.11 : pièces ciblées à l'annonce.
var target_piece_ids: Array[int] = []
## 207.5.14 : Spells de la pile ciblés à l'annonce.
var target_stack_entry_ids: Array[int] = []


func clone() -> StackEntry:
	var copy := StackEntry.new()
	copy.stack_entry_id = stack_entry_id
	copy.kind = kind
	copy.owner = owner
	copy.card = card.clone() if card != null else null
	copy.source_piece_id = source_piece_id
	copy.source_card_instance_id = source_card_instance_id
	copy.source_definition_id = source_definition_id
	copy.allows_response = allows_response
	copy.effect_index = effect_index
	copy.target_cells.assign(target_cells)
	copy.target_piece_ids.assign(target_piece_ids)
	copy.target_stack_entry_ids.assign(target_stack_entry_ids)
	return copy
