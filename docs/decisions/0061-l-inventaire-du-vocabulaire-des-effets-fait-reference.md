# 0061 — L'inventaire du vocabulaire des effets fait référence

- Statut : acceptée
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : vocabulaire d'effets du moteur, `docs/vocabulaire-des-effets.md`, étapes c.5c à c.6 du jalon J2c ; complète 0058 et 0060

## Contexte

Les décisions 0058 et 0060 ont fait grandir le vocabulaire d'effets carte par carte, d'après les 48 cartes du catalogue de playtest. Le moteur ne sait faire que ces cartes, une carte nouvelle risque d'exiger du code, et des tests ont remplacé des textes de cartes pour masquer un manque (Apprenti, Spectre des archives, Trophée : « cette Unit a +N Force »). Le créateur a demandé d'intégrer d'abord tout le vocabulaire décidé, puis les cartes une à une. L'inventaire `docs/vocabulaire-des-effets.md` (verbes, variantes retenues au catalogue §3, axes génériques, mots-clés, synthèse : prêt à coder, à trancher, hors périmètre) a été écrit ; ses questions de règles sont tranchées (ruleset 0.55, décisions de design 0244 à 0253). Contraintes : le ruleset fait foi ; un nouveau `kind` = code et tests avant toute carte (0002) ; enums ajoutés en fin.

## Options envisagées

- A : l'inventaire fait référence. Le moteur code tout ce qu'il marque « à coder », sous forme générique (sujets, portées et filtres combinables côté × type de pièce × position, conditions, déclencheurs, durées, X). Bénéfice : couvre les variantes retenues, pas seulement 48 cartes ; une carte devient une donnée. Coût : un document de plus à tenir, du code au-delà des besoins immédiats mais tout retenu.
- B : grammaire générique complète, tout combinable au-delà de l'inventaire. Bénéfice : aucune carte bloquée. Coût : combinaisons sans règle ni carte, code non vérifié par le jeu, contraire à « une règle avant le code ».
- C : méthode actuelle, inventaire en liste de contrôle, les cartes de c.6 tirent le code. Bénéfice : moins de travail immédiat. Coût : le moteur reste taillé pour les cartes du playtest.

## Décision

Option A. B et C écartées. Choix du créateur, en conversation, le 2026-10-27. `docs/vocabulaire-des-effets.md` fait foi pour le vocabulaire d'effets du moteur. Une ligne n'y entre qu'après une décision de règle ; une carte ne s'écrit qu'avec ce qu'il contient, sinon c'est une question de règle.

## Conséquences et vérification

- Complète 0058 et 0060 : le vocabulaire reste fermé (un enum, une valeur à la fois) mais grandit à partir de l'inventaire, non des cartes ; le réexamen de 0060 « à la troisième condition » ne s'applique plus.
- `/sync-rule` met l'inventaire à jour à chaque édition du ruleset ; `docs/README.md` le référence.
- Roadmap J2c : c.5c devient « Sujets, portées et filtres » et c.5d « Suite d'effets et déclencheurs » ; c.6 n'écrit que des données JSON ; J2c compte 11 étapes.
- Vérification : à la sortie de c.5d, l'inventaire n'a plus de ligne « à coder » et `RULES_AWAITING_IMPLEMENTATION` ne garde que c.6 et c.7.
- Réexamen : si l'inventaire dépasse ce que le ruleset tranche (une ligne « à coder » sans règle), ou après le playtest J3.

## Références

- Décisions 0002, 0010, 0058, 0060 ; `docs/vocabulaire-des-effets.md` ; `docs/catalogue-cartes-playtest.md` §3.
- Ruleset 0.55, décisions de design 0244 à 0253 ; `docs/roadmap.md`, J2c.
