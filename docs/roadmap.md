# Plan de développement

> **Rôle** : plan unique du projet : périmètre, jalons, étapes et état. Les règles font foi dans [ruleset/](ruleset/README.md) ; l'architecture dans [decisions/](decisions/).

**État actuel (22 octobre 2026)** : jalons J0 et J1 terminés ; J2 en cours, étapes 2.1 à 2.6 fusionnées (PR 11 à 16, 32 et 33, assainissement PR 17 à 30, décisions 0038 à 0043) ; à vérifier : le déploiement par la CI et la page en ligne (<https://grisbi95.github.io/tcg-game/>). Corrections de cap du 22 octobre 2026 : action normale par pièce avec réveil, main de départ à 4 cartes (ruleset 0.39, décisions de design 0200 à 0204, décision 0044, PR 34 fusionnée) ; puis temps de tour de 90 s en pause pendant la pile et temps de réponse de 30 s à la place de la pendule, sans défaite au temps, avec défaite par inactivité (ruleset 0.40, décisions de design 0205 et 0206, décision 0045), règles écrites, code à faire. Étape 2.7 ouverte sur `feat/2.7-temps-de-tour` ; questions Q-108 à Q-110 du ruleset ouvertes, les cas qu'elles touchent ne se codent pas ; puis 2.8 (duel à distance, forme du relais WebSocket à décider, 0043). Dettes au [backlog.md](backlog.md), dont l'affichage de l'état endormi et la colonne « PV perdus » du relevé, avant J3 ; questions de règles dans [ruleset/02-questions-ouvertes.md](ruleset/02-questions-ouvertes.md).

## Périmètre

| Sujet | Décision |
| --- | --- |
| Plateformes | Web d'abord (playtests), desktop pour développer. |
| Mode de jeu V1 | Duel à deux joueurs humains : sur un même écran avec relais (0036), ou à distance entre deux navigateurs par un relais WebSocket, l'hôte dans le navigateur du créateur de la partie (0043) ; IA simple au J4. |
| Catalogue | Les decks de test du ruleset (`ruleset/70-playtest/decks-de-test.md`), puis `50-cartes/` quand il existera. |
| Hors périmètre | Serveur de jeu autoritaire et mains cachées par l'architecture (0043), comptes, matchmaking, classement, collection, boutique, IA avancée, mobile. Décision après J3. |

## J0 — Amorçage

- [x] Dépôt `tcg-game`, `.gitignore`, `.gitattributes`, `.editorconfig`, `project.godot` (GL Compatibility, warnings de typage, 1920×1080).
- [x] GdUnit4 6.2.1 repris et vérifié en headless ; `tools/run_tests.sh`.
- [x] Hook `check_gdscript.py` repris, `format_gdscript.py` ajouté, chaîne `post_edit_gdscript.sh`, `session_start.sh` ; `settings.json`.
- [x] gdtoolkit 4 en `.venv`, `.gdlintrc` (100 colonnes, 4 paramètres, 400 lignes), `tools/lint.sh`.
- [x] `tools/sync_ruleset.sh` et copie `docs/ruleset/` à l'édition 0.28 (script retiré par la décision 0014 : le ruleset vit dans le dépôt).
- [x] `CLAUDE.md` racine et locaux (`rules/`, `ui/`, `tests/`), `docs/README.md`, `code-guidelines.md` révisé.
- [x] Agents : `rules-implementer`, `test-writer`, `verifier`, `card-author`, `ui-builder`, `reviewer`, `adr-writer` ; depuis, `ruleset-editor` (0014) ; `godot-ui-ux` ajouté puis retiré le 21 octobre 2026, la conception d'écran se fait en conversation (`ui/CLAUDE.md`). Skills : `implement`, `tests`, `check`, `decision`, `close-step`, `cards` ; `sync-ruleset` retirée par 0014 ; depuis, `open-step`, `pr`, `sync-rule`, `retro` (0039).
- [x] Décisions 0001 à 0007 consignées.
- [x] CI GitHub Actions écrite (tests, lint).
- [x] Remote GitHub `grisbi95/tcg-game` (privé) créé, premier push, CI verte le 16 octobre 2026 (`setup-godot` accepte `4.7.2`).

## J1 — Moteur vérifiable

Chaque étape : règles lues, décision si système nouveau, implémentation par identifiants, tests nommés par identifiants, lint vert.

- [x] **1.1 Fondations** : `DuelState`, `PlayerState`, `Piece`, `CardInstance`, `StackEntry`, `ActiveEffect`, `PendingDecision`, `DuelConfig` (une valeur par règle PROVISOIRE), `BoardGeometry` (201.2), identifiants, `clone()` et son test par réflexion, bases `DuelIntent`, `DuelEvent`, `IntentRejected`. `DeepCompare`, `EventLog`, `DuelStateBuilder` repris du prototype et adaptés.
- [x] **1.2 Catalogue JSON** : `CardDefinition`, `HeroDefinition`, `EffectDefinition`, `TargetSpec`, `CatalogLoader`, `find_errors()`, test du catalogue (201.6, 202.1, 202.2). Forme du schéma : décision 0010 ; s'y ajoutent `Catalog` et `CatalogReader`.
- [x] **1.3 Zones, Essence, tour** : 201, 203, 204 : préparation, Sources et Fonte, paiement `{incliner, recycler}`, mulligan simultané avec Écart, début de tour, pioche et fatigue (209.5), fin de tour sans déclencheur.
- [x] **1.4 Pile et priorité** : 208 sans déclencheurs : annonce, 208.2.4, passes, bloc LIFO, retour au joueur actif ; 209.2 victoire après chaque effet ; `Concede`.
- [x] **1.5 Actions et combat** : 205 et 206 : déploiement (annonce et résolution), action normale, déplacement du Hero, échecs, combat, égalité, Hero défenseur, auras lues avant l'avance, `ForceRules`.
- [x] **1.6 Effets** : 207 et 202.3, 202.4 : Spells et vitesses, statiques, Gear, pouvoir du Hero, durées, cibles et validité, Contrecarrer, jetons.
- [x] **1.7 Déclencheurs et mots-clés** : 207.3, 208.4, 210, 204.5 : liste d'attente des effets déclenchés (décision 0017), attente de fin de bloc, `ORDER_TRIGGERS`, `CHOOSE_TARGETS`, choix unique automatique (0004), « une fois par tour », Arrivée, Dernier souffle, Assaut, Rempart, Avant-poste ; Q-085 du ruleset (205.1.2b).
- [x] **1.8 Pendule** : 209.4 : `advance_clock`, `clock_owners` (les deux pendules pendant le mulligan), temps écoulé, nul (décision 0018).
- [x] **1.9 Cartes de test** : les 17 cartes et le Hero Capitaine en JSON (`/cards decks-de-test`), `data/cards/test_deck.json`, contrôlés carte par carte par `test_test_deck.gd`.
- [x] **1.10 Recette** : `test_rules_coverage.gd` sur `docs/ruleset/`, duels aléatoires avec oracle, déterminisme à graine fixe, `RandomLegalAgent`. **Sortie** : suite verte, chaque règle citée.

## J2 — Partie jouable

- [x] 2.1 `AppEvents`, `DuelHost`, horloge réelle, machine à états de l'hôte ; journal et replay (test de non-régression). Décisions 0020 à 0022.
- [x] 2.2 Composants de vue et scènes d'essai ; `DuelSelection` testé sans scène. Décisions 0023 à 0026.
- [x] 2.3 Écran de duel selon les décisions 0027 à 0035 : plateau, mains, Sources, pile (affichée seulement quand elle n'est pas vide), pendules, cases légales ; pas de journal à l'écran (`DuelJournal`, décision 0022, reste pour le replay et les fiches de playtest) ; fenêtre de réponse de 2 s (208.6, décision de design 0198 ; sans échéance depuis le ruleset 0.38, décision de design 0199), dans l'hôte (décision 0029).
- [x] 2.4 Relais entre joueurs locaux, préparation (decks, graine, mulligan), fin de partie ; scène principale. Décisions 0036 et 0037.
- [x] 2.5 `PlaytestRecorder` : fiche de relevé du protocole en CSV téléchargeable, lue dans le journal rejoué (format 2 : temps des fenêtres de réponse et réponses commencées) ; bouton « Fiche CSV » du panneau de fin. Décision 0042.
- [x] 2.6 Export Web (preset, threads désactivés, filtres d'export), job CI, GitHub Pages sur dépôt public (0005, 0043). **Sortie** : deux joueurs terminent un duel sur un même appareil dans le navigateur, fiche CSV téléchargée.
- [ ] 2.7 Temps de tour et de réponse (0045) : ruleset 0.40 dans le moteur (209.4, 208.6, 209.2.10), `DuelConfig`, hôte, `ClockView`, journal et fiche. **Sortie** : suite verte, un duel montre le temps de tour en pause pendant la pile et la passe à l'expiration des 30 s.
- [ ] 2.8 Duel à distance (0043) : relais WebSocket sans règle, code de partie, écran « Créer / Rejoindre », second écran qui affiche les événements reçus ; le mode même appareil reste. **Sortie** : deux joueurs sur deux ordinateurs terminent un duel dans leur navigateur, fiche produite chez le créateur de la partie.

## J3 — Premier playtest

- [ ] 20 parties selon `ruleset/70-playtest/protocole.md`, fiches automatiques, bilan contre le tableau des cibles et seuils, questions ouvertes du ruleset.

## J4 — IA et catalogue

- [ ] `GreedyAgent` (`clone()`, un coup, évaluation). Intégration de `50-cartes/`. Partie complète contre l'IA.

## Tenue du plan

- Cocher une étape terminée au sens de `CLAUDE.md` §8, puis mettre à jour « État actuel » (cinq lignes au plus, décision 0038) et [backlog.md](backlog.md).
- À la clôture d'un jalon, `/retro` écrit `retros/<jalon>.md` (décision 0039) ; les dettes qu'elle relève vont au backlog.
- Aucune date prévue : seules comptent les étapes et leur ordre. Ce fichier est le seul plan.
