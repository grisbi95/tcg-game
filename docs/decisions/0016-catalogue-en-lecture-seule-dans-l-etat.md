# 0016 — Catalogue en lecture seule dans l'état

- Statut : acceptée
- Date : 2026-10-17
- Décideur : créateur du projet
- Périmètre : accès des modules de `rules/` aux définitions de cartes et de Heroes

## Contexte

À l'étape 1.3, seul `DuelEngine` lisait le `Catalog` (relecture : un module ne reçoit que `state`, pas d'injection). L'étape 1.5 (déploiement, combat) exige que les modules lisent à la demande le coût, le type et la Force imprimée des cartes (202.1, 209.1.1). La question se reposera pour les effets (1.6) et les mots-clés (1.7).

## Options envisagées

- Option A : une référence en lecture seule au `Catalog` dans `DuelState`, à côté de `config`, posée par `DuelEngine` au démarrage et partagée (non copiée) par `clone()`. Les modules lisent `state.catalog.get_card(card.definition_id)`. Simple, aucune copie, même accès pour le moteur, les tests, l'IA et la vue ; mais l'état n'est complet qu'avec son catalogue (le journal de J2 devra noter l'édition du catalogue).
- Option B : copier dans chaque `CardInstance`, à sa création, la Force, le coût et le type de sa définition. L'état se suffit à lui-même ; mais données en double, état et `clone()` plus lourds, et toute nouvelle donnée de carte demande un champ de plus.

## Décision

Option A, choix du créateur, validée le 17 octobre 2026.

## Conséquences et vérification

- `DuelState.catalog` en lecture seule, partagé par `clone()` comme `config` ; `test_duel_state_clone.gd` vérifie le partage.
- `DuelEngine` pose le catalogue au démarrage ; `TurnRules.start_preparation` lit les Heroes par `state.catalog` (le paramètre `heroes` disparaît).
- `DuelStateBuilder` reçoit un catalogue pour les tests qui lisent des définitions.
- Un module ne modifie jamais le catalogue.
- À réexaminer si le replay (J2) ou l'IA (J4) exigent un état indépendant du catalogue.

## Références

Ruleset 202.1, 209.1.1 ; décisions 0001, 0002, 0010 et 0012.
