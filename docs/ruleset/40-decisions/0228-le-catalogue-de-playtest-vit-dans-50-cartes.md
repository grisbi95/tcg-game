# 0228 · Le catalogue de playtest vit dans 50-cartes/

> Décision consignée le 26 octobre 2026. Statut : ACTÉ. Une décision ne se modifie jamais ; pour revenir dessus, une nouvelle décision la remplace et cette ligne reçoit « Remplacée par NNNN ».

## Contexte

La décision 0224 fait jouer le premier playtest avec le catalogue de playtest (4 Heroes, cartes de couleur et neutres, 4 decks de 30 cartes), conçu hors ruleset sur la branche `codex/catalogue-cartes-playtest`. Le README annonçait `50-cartes/` « créé avec la première édition jouable », et `decks-de-test.md` disait ne pas faire partie de ce dossier. Question ouverte d'origine : Q-127.

## Options envisagées

| Option | Pour | Contre |
| --- | --- | --- |
| A · `50-cartes/` est créé maintenant pour le catalogue de playtest, qui fait foi comme les règles ; option recommandée | Les cartes jouées au premier playtest sont dans le dossier qui fait foi. | Le dossier existe avant la première édition jouable annoncée par le README. |
| C · Le catalogue reste hors ruleset jusqu'à la première édition jouable | Le README reste inchangé. | Les cartes jouées au premier playtest ne sont pas dans le dossier qui fait foi. |

## Choix

Le créateur a retenu l'option A le 26 octobre 2026. L'option C est écartée. Une option B (un fichier dans `70-playtest/`) figurait dans la question Q-127 et n'a pas été retenue.

Le journal de conception (choix, pistes, historique, traçabilité) reste hors ruleset, dans `docs/catalogue-cartes-playtest.md` et `docs/catalogue-decks-playtest.md` (branche `codex/catalogue-cartes-playtest`). `50-cartes/` ne reprend que le contenu de jeu de la version de travail 0.1 : les Heroes, les cartes de couleur, les cartes neutres, les decks et les décisions du catalogue sur Trophée et sur la répartition par type.

À mesurer au playtest J3 : les noms, les coûts, les Forces et les textes des cartes, tous provisoires.

## Conséquences sur les règles

- Aucun identifiant créé, modifié ou supprimé par cette décision.
- Dossier `50-cartes/` créé : `README.md`, `heroes.md`, `rouge.md`, `vert.md`, `violet.md`, `bleu.md`, `neutres.md`, `decks.md`.
- `README.md` du ruleset : ligne `50-cartes/` mise à jour. `70-playtest/decks-de-test.md` : phrase de portée mise à jour.
- Glossaire : Catalogue de playtest, Couleur et Neutre ajoutés.
- Q-127 tranchée, option A.

## Questions ouvertes créées

- Q-132 à Q-140 : textes de cartes du catalogue qui contredisent une règle de l'édition 0.48 ou en dépendent sans qu'elle existe, et règle de construction du deck.
