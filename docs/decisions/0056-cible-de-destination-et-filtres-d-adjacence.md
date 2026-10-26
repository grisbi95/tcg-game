# 0056 — Cible de destination d'un effet et filtres d'adjacence

- Statut : acceptée
- Date : 2026-10-26
- Décideur : créateur du projet, en conversation
- Périmètre : `EffectDefinition` et `TargetSpec` du catalogue pour les effets de mouvement ; étape c.3 du jalon J2c

## Contexte

Ruleset 0.52 : chapitres 214 (Échanger), 215 (Déplacer une Unit par un effet), 216 (Renvoyer dans la main), 200.4.2a, 207.5.4a. Le catalogue de `docs/ruleset/50-cartes/` demande : Glissement et Manipulateur « déplacez une Unit ennemie ciblée sur une case libre ciblée adjacente à cette Unit » (une cible pièce et une cible case filtrée par rapport à la pièce) ; Ombre et Stratège échangent « deux Units alliées ciblées distinctes », Stratège ajoutant « adjacentes au Hero » ; Passeur et Reflux renvoient une Unit ennemie de Force N ou moins. Le code : `EffectDefinition` n'a qu'un `TargetSpec` (0010), sans filtre relatif à une autre cible ; une entrée de pile range ses cibles par genre (`target_piece_ids`, `target_cells`, `target_stack_entry_ids`) et chaque effet lit celles du genre que vise sa `TargetSpec`. Contraintes : cibles à l'annonce (`CastSpell`, `AnnounceOrder`) ou par `CHOOSE_TARGETS` pour un effet déclenché (0017), journal des intentions, `DuelSelection` ne gère qu'une cible (c.7).

## Options envisagées

- Option A : une seconde cible « destination » sur l'effet. `EffectDefinition` reçoit un `TargetSpec` facultatif `destination` (une case), exigé pour le `kind` de déplacement et refusé ailleurs par `find_errors()` ; `TargetSpec` gagne deux filtres : « case adjacente à la pièce que cible cet effet » et « adjacente au Hero ». Entrée de pile et intentions inchangées (pièce dans `target_piece_ids`, case dans `target_cells`) ; pour un effet déclenché, `CHOOSE_TARGETS` propose l'ensemble des cases candidates et la validation vérifie l'adjacence à la pièce choisie. Bénéfice : aucun format changé (entrée, intentions, codec, fixture). Coût : un champ propre au déplacement. Limite : un effet ne peut viser deux pièces aux filtres différents (« une Unit alliée et une Unit ennemie ») ; aucune carte du catalogue ne le demande.
- Option B : une liste de cibles par effet. `EffectDefinition.targets: Array[TargetSpec]`, entrée et intentions rangent les cibles par spécification. Bénéfice : générale. Coût : refonte de `StackEntry`, `CastSpell`, `AnnounceOrder`, `ChooseTargets`, du codec, de `DuelSelection` et de la fixture. Limite : étape grossie, touche `ui/`.
- Option C : un `kind` « déplacer vers une case adjacente » qui porte la règle de la case. L'effet ne cible que la pièce, la case vient de `target_cells`, l'adjacence est codée dans le `kind`. Bénéfice : le moins de code. Coût : une partie du texte de la carte vit dans le moteur ; un autre déplacement demandera un autre `kind`. Limite : contraire à l'esprit de 0010.

## Décision

Option A, choisie par le créateur le 2026-10-26. B et C écartées.

## Conséquences et vérification

- Complète 0010 : clé `destination` d'un effet, filtres d'adjacence de `TargetSpec`.
- Travail induit à c.3 : trois `kind` en fin d'`EffectKind` (échanger, déplacer, renvoyer dans la main) avec leurs contrôles dans `find_errors()` ; l'échange exige deux pièces distinctes (214.1.3, texte des cartes), sans trancher Q-098 du ruleset en général ; tests nommés par identifiant.
- Hors c.3 : choix de deux cibles à l'écran (c.7, `DuelSelection`).
- Vérification : suites vertes, chaque règle citée par un test nommé par identifiant.
- Réexamen : à la première carte qui viserait deux pièces aux filtres différents, ou si un second champ propre à un `kind` s'ajoute à `EffectDefinition` (l'option B redevient alors à peser).

## Références

- Décisions 0002, 0010, 0017.
- `docs/ruleset/` édition 0.52, chapitres 214, 215, 216, 200.4.2a, 207.5.4a ; Q-098.
- `docs/roadmap.md` (étape c.3), branche `feat/c.3-effets-de-mouvement`.
