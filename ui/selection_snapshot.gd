class_name SelectionSnapshot
extends RefCounted
## Ce que la sélection montre à un instant (décision 0024) : état, choix en cours, éléments à
## surligner et commandes possibles. Les vues l'affichent sans rien en déduire.

var selection_state: DuelSelection.SelectionState = DuelSelection.SelectionState.IDLE
var chosen_card_id: int = DuelState.NO_ID
var chosen_piece_id: int = DuelState.NO_ID
## Cartes de la main à surligner : à écarter pendant le mulligan, sinon jouables maintenant.
var playable_card_ids: Array[int] = []
var set_aside_card_ids: Array[int] = []
var legal_piece_ids: Array[int] = []
var legal_cells: Array[Vector2i] = []
var legal_stack_entry_ids: Array[int] = []
var ordered_entry_ids: Array[int] = []
## Décision 0023 : paiement préparé pendant le tour adverse, et Sources à montrer après lui.
var draft_payment: EssencePayment = EssencePayment.new()
var shown_upright_sources: int = 0
var shown_tilted_sources: int = 0
var can_pass: bool = false
var can_end_turn: bool = false
var can_confirm: bool = false
## Décision 0023 : vrai pendant le tour adverse, quand le joueur qui a l'écran prépare son paiement.
var is_drafting_payment: bool = false
