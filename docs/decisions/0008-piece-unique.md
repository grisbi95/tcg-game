# 0008 — Un seul type Piece pour le Hero, les Units, les Buildings et les jetons

- Statut : acceptée
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : représentation des pièces du plateau dans `DuelState` (201, 202.3, 202.4)

## Contexte

Le plateau porte le Hero (202.3.2), des Units et des Buildings (202.2.2, 202.2.3) et des jetons (202.4.1). Un jeton ne correspond à aucune carte (202.4.2), reçoit sa Force de l'effet qui le crée (209.1.1a) et cesse d'exister en quittant le plateau (202.4.3). Une case ne porte qu'une pièce (201.0.1) ; un effet cible une pièce, Hero et jeton compris (207.5.11, 207.5.11a, 207.5.11b) ; un Gear ne s'attache qu'à une Unit (202.2.8, 202.2.9).

## Options envisagées

- Option A : un seul type `Piece` avec un champ `kind` (HERO, UNIT, BUILDING) et un champ `card` (`CardInstance`, null pour un jeton). Occupation, ciblage et destruction uniformes, un seul `clone()`. Coût : les champs propres à un genre (PV du Hero, Force du jeton, Gear porté) existent sur toutes les pièces, avec des garde-fous sur `kind` dans les modules.
- Option B : `Piece` de base et sous-classes Hero, Unit, Building, Token. Chaque champ n'existe que là où la règle le permet. Coût : casts à chaque lecture (warnings `unsafe_*`), `clone()` polymorphe à tester par classe, `DeepCompare` et builder plus lourds.
- Option C : Hero hors de la liste, dans `PlayerState`. Plus simple pour les PV. Coût : deux chemins pour 201.0.1, 205.2.3, 206.4 et 207.5.11a.

## Décision

Option A, validée le 16 octobre 2026. `Piece` porte `piece_id`, `kind`, `owner`, `cell`, `card` (null pour un jeton), les PV du Hero, la Force donnée à un jeton et le Gear porté.

`CardInstance` désigne sa définition par un identifiant (`definition_id : StringName`) : `CardDefinition` arrive à l'étape 1.2, et la résolution passe par le catalogue.

## Conséquences et vérification

- `piece_id` n'est jamais réutilisé ; une pièce qui revient sur le plateau reçoit un nouveau `piece_id` (rules/CLAUDE.md). Un jeton n'a ni `card` ni zone de sortie (202.4.4).
- La Force actuelle ne se stocke pas : `ForceRules` la calcule (209.1.1).
- `test_duel_state_clone.gd` donne une valeur non par défaut à chaque champ de `Piece`, d'un Hero, d'une Unit, d'un Building et d'un jeton.
- À réexaminer si les champs propres à un genre dépassent trois, ou si les gardes sur `kind` se répandent hors des modules de règles.

## Références

Ruleset 201.0.1, 202.2.8, 202.3.2, 202.4.1 à 202.4.4, 207.5.11, 209.1.1a ; décisions 0001 et 0007 ; `rules/CLAUDE.md`.
