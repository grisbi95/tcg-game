# 0065 — Valeur du jeu partagée et déclencheurs à objet

- Statut : acceptée
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : lecture d'une valeur du jeu (conditions, X) et objet d'un événement déclencheur, étape c.5e du jalon J2c. Correction de cap : modifie 0058 (`XSource` absorbé) et 0060 (`ConditionKind` remplacé ; déclencheurs nommés avec leur auteur conservés)

## Contexte

Question 1 : deux vocabulaires fermés séparés, `EffectCondition.ConditionKind` (une valeur, `HAND_SIZE_AT_MOST`, 0060, réexamen prévu à la troisième condition) et `EffectDefinition.XSource` (`NONE`, `CHOSEN`, `TARGET_FORCE`, 0058). L'inventaire `docs/vocabulaire-des-effets.md` (axes C et X, 0061) demande des conditions de position, de pièces contrôlées, de Force et de coût (207.3.13, 207.7.1), et X pour piocher et défausser lu sur une valeur du jeu (213.1.8, 213.2.1 : « autant que de cartes défaussées », compte de pièces). Une condition et X lisent tous deux une valeur du jeu.

Question 2 : les déclencheurs « une autre pièce est détruite » et « un Spell est contrecarré » (207.3.1, 207.6.4, 207.3.15) qualifient l'objet de l'événement (« une autre Unit alliée », « un Spell adverse »).

Contraintes : vocabulaire fermé et générique (0002, 0061) ; `PieceFilter` existe (0062, évalué par `ModifierRules.matches_filter`, 0063) ; textes d'effets (0064) ; X d'une valeur du jeu lu une fois à la résolution (213.2.1, 213.2.2) ; condition d'un effet déclenché lue à l'événement (207.3.13) ; déterminisme. Aucune carte de `50-cartes/` n'emploie de condition hors la Pilleuse (taille de main), ni X pour piocher ou défausser.

## Options envisagées

Question 1 :
- A. Une valeur d'enum par condition et par source de X (lignée de 0060 et 0058). Bénéfice : continuité, cas simples à lire. Coût : deux enums qui grossissent en parallèle, une même lecture codée deux fois. Limite : croissance combinatoire, contraire à 0061.
- B. Rien de générique ; une condition ou une source par carte, à la demande. Bénéfice : aucun code sans usage. Coût : sortie de c.5e et ligne C de l'inventaire à corriger. Limite : la première carte qui en demande rouvre une étape de code.
- C. Valeur du jeu partagée : vocabulaire fermé `GameValue` (taille de la main, nombre de pièces d'un `PieceFilter`, Force de la pièce source ou de la cible, cartes défaussées par l'effet précédent, X choisi, coût du Spell de l'événement) ; une condition devient une comparaison `{value, comparison (AT_LEAST, AT_MOST), amount}` ; X se lit sur la même `GameValue` (213.2.1), `XSource` absorbé. Bénéfice : une lecture codée et testée une fois sert aux conditions et à X ; une condition nouvelle est une donnée JSON ; reprend le mot du ruleset. Coût : migration d'`EffectCondition`, de `XSource`, des échantillons de la Pilleuse et des tests de X. Limite : une valeur nouvelle reste du code, par décision.

Question 2 :
- A. Un événement et un filtre de son objet : `TriggerEvent` reçoit `OTHER_PIECE_DESTROYED` et `SPELL_COUNTERED` (à la fin, 0047) ; la pièce détruite est qualifiée par un `PieceFilter` relatif à la pièce qui porte l'effet, le Spell contrecarré par le côté de son propriétaire ; 207.3.15 tient. Bénéfice : deux valeurs d'enum, toute variante est une donnée. Coût : un champ de filtre de plus sur le texte.
- B. Une valeur de `TriggerEvent` par variante (`ALLIED_UNIT_DESTROYED`, `ENEMY_SPELL_COUNTERED`…). Bénéfice : lecture immédiate. Coût : croissance combinatoire.

## Décision

Question 1 : option C. Question 2 : option A. 1A, 1B et 2B écartées. Choix du créateur, en conversation, le 2026-10-27.

## Conséquences et vérification

- `GameValue` : nouvelle classe de catalogue, enum enregistré (valeurs ajoutées à la fin, 0047) ; une seule fonction de lecture dans le module de 213 (`ValueRules`), appelée par les conditions et par X ; un compte de pièces passe par `ModifierRules.matches_filter`.
- `EffectCondition` devient une comparaison (`value`, `comparison` AT_LEAST/AT_MOST, `amount`) ; `HAND_SIZE_AT_MOST` migre en « taille de la main au plus N » ; lecture inchangée (207.3.13 à l'événement, 207.7.1 dans l'ordre du texte).
- `XSource` absorbé par `GameValue` (CHOSEN et TARGET_FORCE repris) ; `amount` « X » admis pour piocher et défausser.
- `TriggerEvent.OTHER_PIECE_DESTROYED` et `SPELL_COUNTERED` ; filtre de l'objet sur le texte (`PieceFilter` de la pièce détruite ; côté du Spell contrecarré) ; auteur selon 0060.
- Migration des échantillons de test et de `data/cards/test_deck.json` dans c.5e. Travail induit : le code et les tests qui citent 0058 ou 0060 (`rules/catalog/effect_condition.gd`, `effect_definition.gd`, `effect_value_checks.gd`, `target_spec.gd`, `catalog_reader.gd`, `rules/value_rules.gd`, `trigger_rules.gd`, `modifier_rules.gd`, `keyword_rules.gd`, `app/intent_codec.gd`, suites de tests de X, de conditions et de déclencheurs).
- Vérification : tests nommés par identifiant (207.3.13, 207.7.1, 207.3.15, 213.2.1) ; une condition et un X lisent la même `GameValue`.
- Réexamen : quand une carte demande une valeur absente de `GameValue`, une comparaison autre que « au moins » ou « au plus », ou un objet d'événement qu'un `PieceFilter` ou un côté ne qualifie pas.

## Références

- Décisions 0002, 0047, 0058 (modifiée), 0060 (modifiée), 0061, 0062, 0063, 0064 ; `docs/roadmap.md`, c.5e ; `docs/vocabulaire-des-effets.md`.
- Ruleset 207.3.1, 207.3.13, 207.3.15, 207.6.4, 207.7.1, 213.1.8, 213.2.1, 213.2.2.
