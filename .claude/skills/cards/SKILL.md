---
name: cards
description: Fait écrire ou mettre à jour les cartes JSON de data/cards/ par l'agent card-author, en n'utilisant que des kind codés. Usage : /cards decks-de-test ou /cards <liste>
---

# Écrire des cartes

1. Vérifie dans `rules/catalog/effect_definition.gd` les `kind` codés. Une carte dont l'effet exige un `kind` absent passe d'abord par `/implement` (code et tests avant la carte, décision 0002).
2. Lance `card-author` avec la source (`docs/ruleset/70-playtest/decks-de-test.md` ou la liste), le fichier cible dans `data/cards/`, et « terminé = test du catalogue vert ».
3. À son retour, relis seulement les cartes laissées de côté et décide : `kind` à coder, ou question ouverte du ruleset.
