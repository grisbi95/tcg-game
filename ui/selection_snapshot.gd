class_name SelectionSnapshot
extends RefCounted
## Ce que la sélection montre à un instant (décision 0024) : état, choix en cours, éléments à
## surligner et commandes possibles. Les vues l'affichent sans rien en déduire.

## Ce que les boutons de choix de la colonne désignent (décision 0068). Ajouter à la fin.
enum ChoiceKind {
	NONE,
	ORDER,  # Ordres du Hero qu'on peut annoncer
	TOP_CARD_PLACE,  # dessus ou dessous pour la carte regardée (217.1.2, 217.1.3)
}

var selection_state: DuelSelection.SelectionState = DuelSelection.SelectionState.IDLE
var chosen_card_id: int = DuelState.NO_ID
var chosen_piece_id: int = DuelState.NO_ID
## Cartes de la main à surligner : à écarter pendant le mulligan, sinon jouables maintenant.
var playable_card_ids: Array[int] = []
## Cartes cliquées en attendant la réponse : à écarter (mulligan) ou à défausser.
var picked_card_ids: Array[int] = []
var legal_piece_ids: Array[int] = []
var legal_cells: Array[Vector2i] = []
var legal_stack_entry_ids: Array[int] = []
var ordered_entry_ids: Array[int] = []
## Décision 0023 : paiement préparé pendant le tour adverse, et Sources à montrer après lui.
var draft_payment: EssencePayment = EssencePayment.new()
var shown_upright_sources: int = 0
var shown_tilted_sources: int = 0
var shown_fonte_sources: int = 0
var can_pass: bool = false
var can_end_turn: bool = false
var can_confirm: bool = false
## Décision 0023 : vrai pendant le tour adverse, quand le joueur qui a l'écran prépare son paiement.
var is_drafting_payment: bool = false
## Décision 0068 : choix de X d'une annonce commencée, borné par ce que le moteur accepte.
var has_x_choice: bool = false
var x_min: int = 0
var x_value: int = 0
var x_max: int = 0
var can_decrease_x: bool = false
var can_increase_x: bool = false
## Annonce sans cible légale avec la valeur courante de X.
var can_confirm_x: bool = false
## Une annonce commencée peut être abandonnée.
var can_cancel: bool = false
var choice_kind: ChoiceKind = ChoiceKind.NONE
## Un bouton par valeur : rang d'un Ordre, ou place de la carte regardée.
var choice_values: Array[int] = []
## Carte du dessus du deck regardée par le joueur, ou NO_ID (201.4.1a, 217.1.5).
var looked_card_id: int = DuelState.NO_ID


## Décision 0068 : X courant, cibles déjà choisies et abandon possible de l'annonce de `assistant`.
func show_announcement(assistant: AnnouncementAssistant, is_cancellable: bool) -> void:
	var chosen := assistant.get_chosen()
	if not chosen.piece_ids.is_empty():
		chosen_piece_id = chosen.piece_ids[0]
	can_cancel = is_cancellable
	has_x_choice = assistant.has_x_cost()
	if not has_x_choice:
		return
	x_min = assistant.get_x_min()
	x_max = assistant.get_x_max()
	x_value = assistant.get_x_value()
	can_decrease_x = assistant.can_decrease_x()
	can_increase_x = assistant.can_increase_x()
	can_confirm_x = assistant.can_confirm_x()


## Surligne les pièces, les cases et les entrées de la pile que portent `targets`.
func show_targets(targets: Array[SelectionTarget]) -> void:
	for target: SelectionTarget in targets:
		legal_piece_ids.append_array(target.piece_ids)
		legal_cells.append_array(target.cells)
		legal_stack_entry_ids.append_array(target.stack_entry_ids)


## Décision 0068 : boutons de choix : places de la carte regardée (217.1.2, 217.1.3), sinon Ordres
## du Hero `hero_id` (NO_ID : aucun).
func show_choice(candidates: SelectionCandidates, hero_id: int) -> void:
	choice_values = candidates.choice_values(hero_id)
	looked_card_id = candidates.looked_card_id()
	if looked_card_id != DuelState.NO_ID:
		choice_kind = ChoiceKind.TOP_CARD_PLACE
	elif not choice_values.is_empty():
		choice_kind = ChoiceKind.ORDER
