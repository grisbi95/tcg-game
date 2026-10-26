# 0055 — Ordre et effets déclenchés du Hero : l'Ordre comme un Spell porté par le Hero

- Statut : acceptée
- Date : 2026-10-26
- Décideur : créateur du projet, en conversation
- Périmètre : catalogue du Hero (passif facultatif, effets déclenchés, Ordres), intention et entrée de pile de l'Ordre ; étape c.2 du jalon J2c

## Contexte

Ruleset 0.52 : chapitre 211 (Ordre du Hero, décision de design 0211), 202.3.11 (passif facultatif, 0212), 202.3.19 à 202.3.22 (le texte du Hero peut porter un Ordre et un effet déclenché ; au moins une capacité, 0218), 201.4.12, 201.5.4c, 204.4.8, 208.1.12, 208.2.3, 208.7.17, 209.2.10, 202.4.6. Le code : `HeroDefinition` ne porte qu'un passif statique obligatoire ; `TriggerRules.trigger` ignore le Hero ; aucune intention ni entrée de pile pour un Ordre (pouvoir du Hero retiré par 0047). Contraintes : `kind` d'effet fermés (0002, 0010), paiement porté par l'intention (0003), cibles à l'annonce (211.4.1), enums journalisables ajoutés en fin, le journal enregistre les intentions (`app/intent_codec.gd`).

## Options envisagées

- Option A : l'Ordre comme un Spell porté par le Hero. `HeroDefinition` porte `passive` (facultatif), `triggered` et `orders` en JSON ; chaque Ordre est un `HeroOrder` (vitesse Action ou Réaction, coût, effets à la résolution) ; intention `AnnounceOrder` (joueur, rang de l'Ordre, paiement, cibles) ; `StackEntryKind.ORDER` en fin d'enum ; résolution par `EffectRules` comme un Spell ; `TriggerRules` lit aussi les effets déclenchés du Hero. Bénéfice : vitesse, priorité, paiement et cibles reprennent les chemins éprouvés du Spell ; un Ordre peut porter plusieurs effets. Coût : une classe de catalogue de plus, recherche de définition à deux branches (carte ou Hero) dans `TriggerRules` et `EffectRules`. Limite : l'Ordre n'est pas une carte et doit rester hors de ce qui vise un Spell (211.1.4 : Contrecarrer, cibles « Spell de la pile »).
- Option B : une liste d'effets avec un timing ORDER. `HeroDefinition.effects` mêle statiques, déclenchés et Ordres, `EffectTiming.ORDER` nouveau, vitesse et coût en champs d'`EffectDefinition`. Bénéfice : aucune classe nouvelle. Coût : champs propres à l'Ordre dans `EffectDefinition`. Limite : un Ordre = un seul effet.
- Option C : une intention d'annonce commune aux Spells et aux Ordres (`CastSpell` généralisée). Bénéfice : un seul chemin. Coût : remaniement d'un chemin qui marche, y compris `DuelSelection`, codec du journal et relais, fixture de rejeu changée. Limite : étape grossie, touche `ui/` prévu en c.7.

## Décision

Option A, choisie par le créateur le 2026-10-26. B et C écartées.

## Conséquences et vérification

- Modifie 0047 : le Hero retrouve une entrée de pile et une intention propres (sous forme d'Ordre) ; les règles de 0047 sur les valeurs d'enum non enregistrées restent valables. Modifie 0010 : clés `passive` (facultative), `triggered` et `orders` du Hero.
- Travail induit à c.2 : `HeroDefinition` et `find_errors()` (passif facultatif, au moins une capacité, 202.3.22), `HeroOrder`, `AnnounceOrder` et ses événements, `StackEntryKind.ORDER`, aiguillage de `DuelEngine`, `TriggerRules` et `EffectRules` pour une source Hero, `app/intent_codec.gd` pour journaliser `AnnounceOrder`, candidats de `RandomLegalAgent` (0019) pour essayer un Ordre ; tests nommés par identifiant ; le Hero Capitaine reste valide.
- Hors c.2 : chemin de sélection de la vue (c.7). Q-116 du ruleset (expiration du temps pendant le choix des cibles d'un Ordre) bloque ce chemin côté hôte et vue, pas le moteur, où les cibles viennent avec l'intention.
- Vérification : suites vertes, chaque règle citée par un test nommé par identifiant.
- Réexamen : si un Hero du catalogue exige un Ordre dont le coût ou la vitesse varie, ou si la recherche de définition à deux branches se répète au-delà de `TriggerRules` et `EffectRules`.

## Références

- Décisions 0002, 0003, 0010, 0019, 0047, 0054.
- `docs/ruleset/` édition 0.52, chapitre 211, décisions de design 0211, 0212, 0218.
- `docs/roadmap.md` (étape c.2), branche `feat/c.2-ordre-du-hero`.
