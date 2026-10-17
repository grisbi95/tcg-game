# 0019 — Agent aléatoire qui essaie des intentions candidates

- Statut : acceptée
- Date : 2026-10-17
- Décideur : créateur du projet
- Périmètre : `ai/` (premier fichier du dossier), agent `RandomLegalAgent` de l'étape 1.10 (duels aléatoires avec oracle, déterminisme) ; prépare `GreedyAgent` (J4)

## Contexte

L'étape 1.10 fait jouer au moteur des duels entiers au hasard, à graine fixe, pour vérifier après chaque coup des invariants et les conditions du ruleset (`tests/CLAUDE.md`, « Duels aléatoires »). Il faut un agent qui produise à chaque instant une intention légale quelconque, sans mettre de règle dans `ai/` (couches de `CLAUDE.md` §3 : `ai/` ne connaît que `rules/` et `data/`).

## Options envisagées

- Option A : l'agent essaie. Il fabrique des intentions candidates à partir de l'état en lecture (déployer chaque carte de la main sur chaque case, action normale de chaque pièce vers chaque case adjacente, Spells et Gear avec chaque cible plausible, pouvoir du Hero, passer, terminer le tour, répondre à une attente : mulligan, ordre, cibles), avec un paiement simple (incliner d'abord, recycler le reste), et ne garde que celles que `DuelEngine.validate()` accepte ; il en tire une par son propre `RandomNumberGenerator` à graine. Le moteur ne change pas et reste seul juge des règles.
- Option B : le moteur expose `legal_intents()`. Une seule source, réutilisable par la vue et l'IA ; mais le moteur grossit, la validation se double d'une énumération, et la liste explose (paiements, cibles).
- Option C : agent minimal (passer, terminer le tour, garder sa main). Très simple ; mais il ne teste ni combats, ni Spells, ni déclencheurs.

## Décision

Option A, validée le 17 octobre 2026 par le créateur.

## Conséquences et vérification

- `ai/random_legal_agent.gd`, `RefCounted`, sans Node : `choose_intent(engine) -> DuelIntent` pour le joueur que le moteur attend (attente en cours, sinon joueur qui a la priorité si la pile n'est pas vide, sinon joueur actif) ; aucune règle de jeu, aucun appel à `submit()`.
- Son aléa vient de sa propre graine, distincte de `DuelState.rng` : même état, même graine de l'agent ⇒ même intention (déterminisme, décision 0001).
- Les candidates couvrent toutes les classes d'intention du moteur ; une intention légale absente des candidates (par exemple un paiement inhabituel) n'est pas tirée : l'agent ne prétend pas énumérer tous les coups légaux.
- Tests : à graine fixe, chaque intention choisie est acceptée par `validate()` ; des duels entiers vont jusqu'à leur fin ou à une limite de coups ; deux exécutions à mêmes graines donnent états et événements égaux (`DeepCompare`).
- À réexaminer si la vue ou l'IA de J4 a besoin de la liste des coups légaux (option B).

## Références

`CLAUDE.md` §3 (couches, déterminisme) ; `tests/CLAUDE.md` (duels aléatoires, déterminisme) ; décisions 0001, 0003, 0009 ; roadmap, étape 1.10.
