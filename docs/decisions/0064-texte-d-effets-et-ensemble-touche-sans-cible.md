# 0064 — Texte d'effets et ensemble touché sans cible

- Statut : acceptée
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : suite d'effets d'un même texte et effet sur un ensemble non ciblé, étape c.5d du jalon J2c

## Contexte

Chaque `EffectDefinition` déclenchée (timing TRIGGERED) donne sa propre entrée de pile (`StackEntry.effect_index`, `Catalog.triggerable_effects`) et le joueur ordonne les entrées (208.4.6). Le ruleset 0.55 veut que les effets d'un même texte s'appliquent dans l'ordre du texte (207.7.4), avec « si vous le faites » (207.7.6 à 207.7.6b) et une condition « si » lue quand l'effet vient dans l'ordre du texte (207.7.1 à 207.7.3, 211.1.5). Cas : Chantier (« …créez un jeton Unit de Force 4 sur une case libre ciblée adjacente…, puis détruisez ce Building »), Grimoire (« …piochez une carte, puis défaussez une carte de votre main »). Les Spells et Ordres n'ont pas ce problème : `EffectRules.resolve_all` résout déjà leur liste dans l'ordre.

Question 2 : un effet qui touche un ensemble sans le cibler (« les Units ennemies ont −1 Force jusqu'à la fin du tour ») : ensemble fixé à la résolution (207.4.11 à 207.4.11c), seul « ciblée » désigne une cible (207.5.18).

Contraintes : vocabulaire fermé et générique (0002, 0010, 0061) ; cibles portées par l'entrée de pile par genre ; `PieceFilter` existe (0062, 0063) ; « une fois par tour » compté par effet déclenché (207.3.7c) ; déterminisme ; aucune carte de `50-cartes/` encore en JSON (c.6), donc migration peu coûteuse maintenant.

## Options envisagées

Question 1 :
- A. Suite imbriquée (`then: [EffectDefinition…]` sur l'effet de tête, résolue dans la même entrée). Bénéfice : frontière explicite, effets suivants sans déclencheur ni « une fois par tour ». Coût : deux formes (liste plate des Spells et Ordres, imbrication des déclenchés), ou Spells unifiés sur `then`. Limite : second rang dans la clé « une fois par tour » et dans la reprise après un choix (0057), `resolving_effect_index` imbriqué.
- B. Objet `EffectText` : une carte, un Hero ou un Ordre porte des `texts` ; chaque texte a son `timing`, son déclencheur, sa mention « une fois par tour », sa condition lue à l'événement (207.3.13) et une liste ordonnée d'`effects` ; chaque effet garde sa condition « si » (207.7.1a) et un drapeau `if_you_do` (207.7.6) ; une entrée de pile résout un texte. Bénéfice : reprend le mot du ruleset ; une seule forme pour Spells, Ordres, déclenchés et statiques ; clé (carte, rang du texte) sans ambiguïté. Coût : migration la plus lourde (`CardDefinition`, `HeroDefinition`, `HeroOrder`, `TriggerRules`, `test_deck.json`, échantillons de test). Limite : un statique reste un texte à un seul effet.
- C. Drapeau de continuité : liste plate gardée, `continues_previous: true` rattache un effet au texte du précédent. Bénéfice : changement minimal, rien à migrer. Coût : frontière déduite de l'ordre de la liste, contrôles de catalogue à ajouter. Limite : modèle d'« effets » face à un ruleset de « textes », plus cher à refaire après c.6.

Question 2 :
- A. Sujet `EffectSubject.MATCHING_PIECES` : l'effet décrit son ensemble par un `PieceFilter` (0062), relatif à la pièce source ou au joueur ; ensemble calculé une fois à la résolution (207.4.11) ; effet à durée posé par pièce, donc une pièce arrivée après n'est pas touchée (207.4.11a) et une pièce touchée le reste même si elle ne correspond plus (207.4.11c). Bénéfice : réutilise 0062 et l'effet à durée par pièce. Coût : un sujet de plus, contrôlé kind par kind.
- B. `TargetSpec` « toutes les pièces légales ». Bénéfice : aucun sujet nouveau. Coût : mêle cible et ensemble, contraire à 207.5.18 ; validation des cibles et « sans cible légale » (207.5.5) s'appliqueraient à tort.

## Décision

Question 1 : option B. Question 2 : option A. 1A, 1C et 2B écartées. Choix du créateur, en conversation, le 2026-10-27.

## Conséquences et vérification

- Nouvelle classe de catalogue `EffectText` (timing, trigger, once_per_turn, condition à l'événement, effects ordonnés) ; `CardDefinition`, `HeroDefinition` (passif, déclenchés) et `HeroOrder` portent des textes ; `EffectDefinition` perd `timing`, `trigger` et `once_per_turn`, garde sa condition « si » (207.7.1a, lue dans l'ordre du texte) et reçoit `if_you_do` (207.7.6).
- Une entrée de pile d'effet déclenché résout un texte (`effect_index` devient le rang du texte) ; la reprise après un choix (0057) garde le rang de l'effet dans le texte ; la clé « une fois par tour » devient (carte ou jeton, rang du texte).
- Les cibles restent portées par l'entrée de pile par genre ; chaque effet du texte lit celles du genre que vise sa `TargetSpec`.
- `EffectSubject.MATCHING_PIECES` ajouté à la fin de l'enum (0047) ; ensemble lu par `ModifierRules.matches_filter` (0063).
- Migration de `data/cards/test_deck.json` et des échantillons de test dans c.5d ; aucune carte de `50-cartes/` n'est encore écrite.
- Une condition « si » sur un effet qui suit un autre effet dans un texte déclenché, lue à la résolution, relève de 207.7 ; si le ruleset ne la couvre pas pour un texte déclenché, la question part au ruleset, le code ne la tranche pas.
- Vérification : tests nommés par identifiant (207.7.4, 207.7.6, 207.4.11a, 207.4.11c) ; Chantier et Grimoire résolus dans l'ordre du texte.
- Réexamen : si un texte doit porter plusieurs déclencheurs, ou si une carte demande qu'un effet d'un texte dépende d'un effet autre que celui qui le précède immédiatement.

## Références

- Décisions 0002, 0010, 0047, 0057, 0061, 0062, 0063 ; `docs/roadmap.md`, c.5d.
- Ruleset 207.3.7c, 207.3.13, 207.4.11 à 207.4.11c, 207.5.18, 207.7.1 à 207.7.6b, 208.4.6, 211.1.5.
