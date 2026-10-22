# 0044 — État endormi ou éveillé porté par la pièce

- Statut : acceptée
- Date : 2026-10-22
- Décideur : créateur du projet
- Périmètre : état « endormi ou éveillé » des Units et du Hero dans le moteur (`Piece`, `ActionRules`, `TurnRules`, `PreparationRules`, `EffectRules`, `IntentRejected`)

## Contexte

Le ruleset passe en édition 0.39 (décision de design 0200, `docs/ruleset/40-decisions/0200-action-normale-par-piece-et-reveil.md`) : la limite « une action normale par tour » (204.4.6, supprimée) est remplacée par une action normale par pièce, avec réveil. Une Unit ou un Hero est endormi ou éveillé (205.5.1, 205.5.2). Toute Unit qui arrive sur le plateau est endormie, jeton et Unit entrée en attaquant compris (205.5.4, 205.5.4a, 205.5.4b) ; le Hero placé à la préparation est endormi (204.1.18). Au début de son tour, un joueur réveille ses Units et son Hero, en première étape (204.3.8, 204.3.10, 204.3.11). Une pièce endormie ne peut pas faire d'action normale (205.5.3) ; elle s'endort dès l'annonce de son action normale, même si celle-ci échoue (205.4.7). Un Building n'est ni endormi ni éveillé (205.5.6). Le moteur portait un booléen par joueur, `PlayerState.normal_action_used_this_turn`, remis à zéro à chaque début de tour. Une simulation de 1000 parties par variante (hors dépôt) a motivé le changement de règle ; elle est consignée dans la décision 0200 du ruleset.

## Options envisagées

- Option 1 : champ sur `Piece`. `Piece.is_awake: bool`, copié dans `clone()`, faux à la création de toute pièce, vrai au réveil, faux à l'annonce ; `PlayerState.normal_action_used_this_turn` disparaît. Bénéfice : l'état vit avec la pièce, une pièce qui revient est une nouvelle pièce donc endormie sans code dédié (210.3.1a), lecture directe par la vue. Coût : un champ d'état de plus dans `clone()` et son test ; les tests qui construisent un état doivent dire si leurs pièces sont éveillées.
- Option 2 : liste sur `PlayerState`. `pieces_asleep: Array[int]`, vidée au réveil, complétée à l'arrivée et à l'annonce. Bénéfice : `Piece` inchangée. Coût : il faut retirer l'identifiant quand une pièce quitte le plateau ; deux sources à garder cohérentes.

## Décision

Option 1, choisie par le créateur le 2026-10-22.

- `is_awake` est faux à la création de toute pièce (déploiement, entrée en attaquant, jeton, Hero de la préparation), vrai au réveil (`TurnRules.start_turn`, avant le redressement), faux à l'annonce (`ActionRules.announce_normal_action`).
- Nouvelle raison de refus `PIECE_ASLEEP`, ajoutée en fin de `IntentRejected.RejectReason`. `NORMAL_ACTION_ALREADY_USED` reste dans l'enum (journalisable) mais n'est plus jamais produite.
- Un événement de réveil, un par fait observable.

## Conséquences et vérification

- Fichiers touchés : `rules/piece.gd` (champ, `clone()`), `rules/action_rules.gd` (validation, annonce), `rules/turn_rules.gd` (réveil), `rules/preparation_rules.gd` et `rules/effect_rules.gd` (création), `rules/player_state.gd` (champ retiré), `rules/events/` (événement de réveil), `rules/events/intent_rejected.gd` (raison en fin d'enum), `tests/support/duel_state_builder.gd`, test de clonage.
- La vue n'affiche pas encore l'état endormi : dette portée au backlog, à régler avant le premier playtest humain (J3). La visibilité de cet état pour l'adversaire est une question ouverte du ruleset (Q-104).
- Le replay de non-régression (0022) peut changer : la fixture se régénère s'il le faut, écart à dire dans le rapport.
- Vérification : tests nommés 204.1.18, 204.3.8, 205.4.7, 205.5.3 et 205.5.4 (dont 205.5.4a et 205.5.4b), test de clonage de `Piece`, suite de replay verte.
- À réexaminer : si un effet de carte doit endormir ou réveiller une pièce hors du début du tour, ou si un autre état « par pièce et par tour » apparaît (deux champs de même nature appellent une structure commune).

## Références

Ruleset 0.39, décision de design 0200 (`docs/ruleset/40-decisions/0200-action-normale-par-piece-et-reveil.md`) ; règles 204.1.18, 204.3.8, 204.3.10, 204.3.11, 205.4.7, 205.5.1 à 205.5.6, 210.3.1a ; question ouverte Q-104 ; décisions 0008, 0022 ; `docs/backlog.md`.
