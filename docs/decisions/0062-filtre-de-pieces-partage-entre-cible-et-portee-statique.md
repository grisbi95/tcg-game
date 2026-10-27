# 0062 — Filtre de pièces partagé entre cible et portée statique

- Statut : acceptée
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : filtres de pièces des effets (`TargetSpec`, `EffectDefinition.StaticScope`), étape c.5c du jalon J2c (branche `feat/c.5c-sujets-portees-filtres`) ; applique 0061, précise 0056

## Contexte

Chaque « quelles pièces » s'écrit aujourd'hui par une valeur d'enum isolée : `TargetSpec.side`, `TargetSpec.piece_kinds`, `CellRow` (`ANY`, `OWN_FIRST`), `AdjacentTo` (`NONE`, `TARGET_PIECE`, `OWN_HERO`, `SOURCE_PIECE`, 0056), `EffectDefinition.StaticScope` (`NONE`, `BEARER`, `ADJACENT_ALLIED_UNITS`) évaluée par `ModifierRules.scope_touches`. L'étape c.5c (axes T, F, P de `docs/vocabulaire-des-effets.md`, 0061) demande de croiser côté × type de pièce × position, pour la cible choisie (207.5.6) comme pour la portée d'un effet statique (206.5.4, 206.5.5, 207.2.2, 207.2.8) : autres Units alliées adjacentes (Porte-enseigne), même rangée (Ancien du bosquet), Units ennemies adjacentes (Obélisque), Units alliées adjacentes au porteur d'un Gear (Bannière) ; plus « non jeton » (202.4.1), « distinctes » sur des cases, rangées nommées par 205.1 (hors rangée centrale 205.1.4, deux rangées les plus proches 205.1.3, rangée d'une pièce), filtres sur le Spell ciblé (coût X compris 213.1.6/213.1.7, vitesse 207.1.2). Contraintes : forme générique (0061), vocabulaire fermé (0002, 0010), chapitre 207 déjà à cinq modules (0059, aucun module nouveau), moteur pur et déterministe, enums du JSON étendus à la fin (0047). Seul `data/cards/test_deck.json` emploie ces champs aujourd'hui.

## Options envisagées

- A : ajouter des champs et des valeurs d'enum (`CellRow` étendu ; `TargetSpec` reçoit `piece_row`, `exclude_tokens`, `distinct`, `spell_max_cost`, `spell_speeds` ; `StaticScope` une valeur par motif). Bénéfice : changement minimal, rien à migrer. Coût : une même portée et une même cible codées deux fois (`scope_touches` et `EffectRules`). Limite : `StaticScope` croît de façon combinatoire, ce que 0061 veut éviter.
- B : un `PieceFilter` partagé, classe de catalogue portant `side`, `piece_kinds`, `relation` à une pièce de référence (`ANY`, `SELF`, `ADJACENT`, `SAME_ROW`), `include_reference` (« autres »), `tokens` (`ANY`, `NON_TOKEN`), `row` (zone nommée par 205.1). La portée statique devient un `PieceFilter` dont la référence est le porteur (207.2.8) ; la cible pièce de `TargetSpec` l'emploie à la place de ses champs de pièce. Un seul évaluateur `matches(state, reference, owner, piece)` dans `EffectRules`, lu aussi par `ModifierRules`. Cases et Spells gardent leurs filtres propres dans `TargetSpec`. Bénéfice : une seule lecture de la position pour cible et portée, chaque axe codé et testé une fois, un croisement nouveau = une donnée JSON. Coût : une classe de plus, migration des champs de `TargetSpec` et de `test_deck.json`, réécriture des tests de portée. Limite : axes fixés d'avance ; un axe nouveau (Force, mot-clé) reste du code, par décision.
- C : liste de prédicats atomiques combinés par ET, pour pièces, cases et Spells. Bénéfice : le plus ouvert. Coût : validation de combinaisons incohérentes, JSON verbeux, messages d'erreur du catalogue plus durs. Limite : vocabulaire mal fermé, des filtres sans décision de règle deviennent écrivables, contre 0061.

## Décision

Option B. A et C écartées. Choix du créateur, en conversation, le 2026-10-27.

## Conséquences et vérification

- Nouvelle classe `rules/catalog/piece_filter.gd` avec `from_dict` et `find_errors()` ; évaluation dans `EffectRules` (207.5.6), appelée par `ModifierRules` pour les portées (206.5.5) ; aucun module nouveau.
- `TargetSpec` délègue ses filtres de pièce à un `PieceFilter` ; il garde ses filtres de case (rangées, « distinctes ») et de Spell ciblé (coût, X compris, vitesse).
- `StaticScope` est remplacé par un `PieceFilter` relatif au porteur ; `BEARER` = relation `SELF`. Migration de `data/cards/test_deck.json` et des tests de portée dans la même étape.
- « Distinctes » reste une pratique de rédaction écrite par la carte ; la règle générale de distinction reste Q-098, non tranchée en code. Un Hero reste refusé comme cible de `MODIFY_FORCE` et `DESTROY` tant que Q-097 est ouverte.
- `docs/vocabulaire-des-effets.md` (axes T, F, P) est mis à jour en fin d'étape ; vérification : chaque ligne « à coder » de ces axes est codée et testée.
- Réexamen : quand une carte demande un axe que `PieceFilter` n'a pas (Force, mot-clé, état éveillé ou endormi), ou si un filtre de case ou de Spell doit aussi se croiser avec la position d'une pièce.

## Références

- Décisions 0002, 0010, 0047, 0056, 0059, 0061 ; `docs/vocabulaire-des-effets.md` ; `docs/roadmap.md`, c.5c.
- Ruleset 202.4.1, 205.1, 206.5.4, 206.5.5, 207.1.2, 207.2.2, 207.2.8, 207.5.6, 213.1.6, 213.1.7 ; questions Q-097 et Q-098.
