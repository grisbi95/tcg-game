# 0063 — Évaluateur du filtre de pièces dans ModifierRules

- Statut : acceptée
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : lieu de l'évaluation de `PieceFilter` et noms retenus, étape c.5c du jalon J2c ; précise 0062

## Contexte

0062 place l'évaluation unique du `PieceFilter` dans `EffectRules`, appelée par `ModifierRules` pour les portées. À l'implémentation (étape c.5c), cela crée une boucle d'appels entre deux modules du chapitre 207, `EffectRules` appelant déjà `ModifierRules` pour les effets à durée : c'est le motif de réexamen de 0059. De plus, `BoardGeometry` devait connaître `PieceFilter.RowZone`, d'où un cycle de dépendances avec le catalogue. Relevé par la relecture.

## Options envisagées

- A : l'évaluateur (`matches_filter`, lecture des zones de rangée) vit dans `ModifierRules` (207.2), appelé par `EffectRules` et `TriggerTargets` ; `BoardGeometry` garde ses seuls prédicats de rangée. Bénéfice : dépendances à sens unique, 0059 respectée sans réexamen, une seule évaluation. Coût : un filtre de cible (207.5.6) évalué dans le module des effets statiques ; la carte des modules doit le dire. Limite : `ModifierRules` grossit ; à surveiller si les filtres de case et de Spell s'y ajoutent.
- B : garder l'évaluateur dans `EffectRules` et accepter la boucle `EffectRules` ↔ `ModifierRules` en réexaminant 0059. Bénéfice : conforme au texte de 0062. Coût : une boucle de plus entre modules frères, alors que le backlog en traite déjà une (`CombatRules`, `EffectRules`, `TriggerRules`). Limite : contredit le motif de réexamen de 0059.
- C : l'évaluation dans `PieceFilter` lui-même (classe du catalogue), l'état en paramètre. Bénéfice : aucune dépendance entre modules. Coût : une classe de données lit l'état du duel et les règles de position ; `catalog/` cesse d'être de la donnée pure. Limite : les filtres de règle sortent du module de leur chapitre (0007).

## Décision

Option A. B et C écartées. Choix du créateur, en conversation, le 2026-10-27, après avoir constaté l'écart avec 0062.

## Conséquences et vérification

- Sur le lieu d'évaluation, cette décision l'emporte sur 0062 : `ModifierRules.matches_filter`, appelé par `EffectRules` et `TriggerTargets` ; `BoardGeometry` ne connaît pas le catalogue. La carte des modules (`rules/CLAUDE.md`) le dit.
- Noms retenus : champ de référence `relative_to` (pièce source ou Hero du joueur) et enum de côté `SideFilter` (conflits de noms avec Godot).
- `max_force` reste dans `TargetSpec` : une portée statique qui lirait la Force bouclerait sur le calcul de la Force.
- `StaticScope`, `TargetSide`, `CellRow` et `AdjacentTo.OWN_HERO` sont supprimés (0047 : aucune fixture ne les enregistre, le JSON se lit par nom).
- Un passif de Hero `modify_force` à portée `self` est refusé par le catalogue tant que Q-097 est ouverte.
- Vérification : aucune boucle d'appels entre `EffectRules` et `ModifierRules` ; tests de filtre nommés par identifiant de règle.
- Réexamen : si `ModifierRules` dépasse la limite de lignes, ou si un filtre doit lire la Force.

## Références

- Décisions 0007, 0047, 0059, 0062 ; `docs/roadmap.md`, c.5c.
- Ruleset 207.2, 207.5.6 ; question Q-097.
