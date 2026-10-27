# 0058 — Valeur X d'un effet et mots-clés accordés

- Statut : acceptée
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : `CardDefinition`, `EffectDefinition`, `TargetSpec`, `CastSpell`, `StackEntry`, `EffectRules`, `KeywordRules` ; étape c.5a du jalon J2c

## Contexte

Ruleset 0.53, chapitre 213 : coût X d'un Spell choisi à l'annonce, au moins 1, payé à l'annonce, X avant les cibles, légalité des cibles lue avec X, X vaut 0 hors de la pile (213.1) ; X défini par un texte, lu une fois à la résolution, Force de l'Unit sans Assaut ni Rempart (213.2) ; 209.4.4h et 209.4.11b (temps pendant le choix de X, abandon de l'annonce à l'expiration). Catalogue de `docs/ruleset/50-cartes/` : Exécution (coût X, « détruisez une Unit ennemie ciblée de Force X ou moins »), Furie et Sève (« a Assaut X / Rempart X jusqu'à la fin du tour, X étant sa Force à la résolution »), Hache de guerre et Cape d'ombre (Gear : Assaut 2 / Rempart 2 pour la Unit porteuse), Tambour de guerre (Building : Assaut 1 pour les Units alliées adjacentes). Le code : `CardDefinition.cost` est un entier ; Assaut et Rempart ne viennent que des `keywords` de la carte (`KeywordRules`) ; `MODIFY_FORCE` gère déjà durées, portées statiques (`BEARER`, `ADJACENT_ALLIED_UNITS`) et fin des effets (207.4.7a). Contraintes : le JSON décrit la carte (0002, 0010) ; X est écrit une seule fois sur une carte (210.1.2) ; journal des intentions ; X arrive avec l'intention comme les cibles (le choix à l'écran est en c.7).

## Options envisagées

Question 1, représenter X.

- Option A : un seul X par effet, défini par `x_source`. JSON : `"cost": "X"` sur la carte, `"max_force": "X"` ou `"amount": "X"` sur l'effet ; `EffectDefinition.x_source` dit d'où vient X (choisi à l'annonce, 213.1 ; Force de la cible à la résolution, 213.2.3, sans Assaut ni Rempart, 213.2.4) ; `CastSpell.x_value` et `StackEntry.x_value` portent la valeur choisie ; coût 0 hors de la pile (213.1.7). Bénéfice : le JSON suit le texte, où X est écrit une fois. Limite : un effet ne peut avoir deux X différents ; aucune carte ne le demande.
- Option B : une source de valeur par champ numérique (fixe, X choisi, Force de la cible). Bénéfice : plus général. Coût : la lecture de tous les champs numériques change, sans carte qui le demande.

Question 2, mots-clés accordés.

- Option A : un `kind` `GRANT_KEYWORD` sur le modèle de `MODIFY_FORCE`, avec mot-clé (Assaut ou Rempart) et valeur ; effet à la pile avec durée (Furie, Sève), statique sur le porteur (`BEARER` : Hache de guerre, Cape d'ombre), aura (`ADJACENT_ALLIED_UNITS` : Tambour de guerre) ; `KeywordRules` additionne valeur de la carte, statiques et effets actifs. Bénéfice : réutilise durées, portées et fin des effets déjà codées.
- Option B : un attribut de carte « accorde ces mots-clés » avec portée sur le Gear ou le Building, plus un effet actif seulement pour Furie et Sève. Coût : deux chemins pour la même chose.

## Décision

Question 1 : option A. Question 2 : option A. B écartée dans les deux cas. Choix du créateur, 2026-10-27.

## Conséquences et vérification

- Complète 0010 : clés `cost` « X », `x_source`, valeurs « X » des champs, `kind` `GRANT_KEYWORD` (ajouté en fin d'`EffectKind`).
- Travail induit à c.5a : `CardDefinition` (coût X réservé aux Spells, 213.1.2, sans partie fixe, 213.1.12), `EffectDefinition`, `TargetSpec` (« Force X ou moins »), `CastSpell`, `StackEntry`, `EffectRules`, `KeywordRules`, `IntentCodec`, `RandomLegalAgent` (choisit X) ; tests par identifiant de 213, 209.4.4h, 209.4.11b.
- Hors c.5a : déclencheurs (c.5b), autres portées (c.5c), choix de X à l'écran (c.7).
- Vérification : suites vertes, chaque règle de 213 citée par un test nommé par identifiant.
- Réexamen : à la première carte qui porte deux X différents, ou un autre mot-clé à valeur accordé par un effet.

## Références

- Décisions 0002, 0010, 0057.
- `docs/ruleset/` édition 0.53, chapitre 213, 209.4.4h, 209.4.11b, 210.1.2, 207.4.7a.
- `docs/roadmap.md` (étape c.5a), branche `feat/c.5a-cout-x-et-mots-cles`.
