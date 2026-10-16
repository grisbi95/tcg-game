# Plan de développement

> **Rôle** : plan unique du projet : périmètre, jalons, étapes et état. Les règles font foi dans [ruleset/](ruleset/README.md) ; l'architecture dans [decisions/](decisions/).

**État actuel (16 octobre 2026)** : jalon J0 terminé ; J1 étapes 1.1 et 1.2 terminées, fusionnées dans `main` par la PR 1 avec l'outillage Godot AI (0011), CI verte. 1.2 : `rules/catalog/` (`CardDefinition`, `HeroDefinition`, `EffectDefinition` avec `EffectKind` MODIFY_FORCE, DESTROY, COUNTER_SPELL, CREATE_TOKEN, `TargetSpec`, `Catalog`, `CatalogLoader`, `CatalogReader`, chacun avec `find_errors()`), outil de test `CatalogSamples`, 155 tests verts dont les suites `test_catalog*.gd`, lint propre. `data/cards/` ne contient que `.gitkeep` : les cartes de test viennent à l'étape 1.9, après le code des `kind` (1.6, 1.7). Décisions 0001 à 0015 : 0012 (`DuelSetup`, premier joueur imposé) et 0013 (mulligans à la dernière réponse) consignées pour 1.3 ; 0014 : ruleset fusionné dans `docs/ruleset/` avec son historique, plus de copie ni de synchronisation ; 0015 : mulligans exécutés joueur A puis B. Étape 1.3 en cours sur `feat/1.3-turn` : bloc 201 fait (`ZoneRules` : création du deck, pioche avec limite de main, Écart ; `test_201_zones.gd`). Ruleset 0.30 : Q-075 à Q-079 tranchées (décisions de design 0176 à 0180 ; règles 203.2.6, 203.2.7, 204.1.16, 204.1.17, 204.2.12 à 204.2.14, 209.5.2a, 209.5.4a), Bloc 203 fait (`EssenceRules` : paiement `EssencePayment` {incliner, recycler} validé puis appliqué, 203.2.6 compris ; `test_203_essence.gd`). Bloc 204 fait : façade `DuelEngine` (`start_new_duel` par `DuelSetup`, `start_from_state`, `validate`, `submit`, `get_state`), `TurnRules` (préparation dans l'ordre de 204.1.16, mulligan simultané exécuté A puis B, premier joueur tiré après le mulligan, début du tour 204.3.8, fin du tour sans déclencheur avec 204.5.7), `StateCheckRules` pour la fatigue (209.5) ; intentions `ChooseMulligan`, `EndTurn` ; suites `test_204_preparation.gd`, `test_204_turn.gd`, `test_209_5_fatigue.gd`, `test_duel_engine.gd` ; 250 tests verts, lint propre. Reste à clore 1.3 (`/close-step 1.3`). Hors 1.3 : le Hero peut descendre sous 0 PV par la fatigue sans fin de partie tant que 209.2 n'est pas codée (1.4) ; le protocole de playtest impose le premier joueur d'avance, à préciser avant J3 pour respecter 204.1.16 (annonce après le mulligan).

## Périmètre

| Sujet | Décision |
| --- | --- |
| Plateformes | Web d'abord (playtests), desktop pour développer. |
| Mode de jeu V1 | Duel local à deux joueurs sur un écran avec relais ; IA simple au J4. |
| Catalogue | Les decks de test du ruleset (`ruleset/70-playtest/decks-de-test.md`), puis `50-cartes/` quand il existera. |
| Hors périmètre | Réseau, comptes, matchmaking, classement, collection, boutique, IA avancée, mobile. Décision après J3. |

## J0 — Amorçage

- [x] Dépôt `tcg-game`, `.gitignore`, `.gitattributes`, `.editorconfig`, `project.godot` (GL Compatibility, warnings de typage, 1920×1080).
- [x] GdUnit4 6.2.1 repris et vérifié en headless ; `tools/run_tests.sh`.
- [x] Hook `check_gdscript.py` repris, `format_gdscript.py` ajouté, chaîne `post_edit_gdscript.sh`, `session_start.sh` ; `settings.json`.
- [x] gdtoolkit 4 en `.venv`, `.gdlintrc` (100 colonnes, 4 paramètres, 400 lignes), `tools/lint.sh`.
- [x] `tools/sync_ruleset.sh` et copie `docs/ruleset/` à l'édition 0.28.
- [x] `CLAUDE.md` racine et locaux (`rules/`, `ui/`, `tests/`), `docs/README.md`, `code-guidelines.md` révisé.
- [x] Agents : `rules-implementer`, `test-writer`, `verifier`, `card-author`, `ui-builder`, `reviewer`, `adr-writer`. Skills : `implement`, `tests`, `check`, `decision`, `sync-ruleset`, `close-step`, `cards`.
- [x] Décisions 0001 à 0007 consignées.
- [x] CI GitHub Actions écrite (tests, lint).
- [x] Remote GitHub `grisbi95/tcg-game` (privé) créé, premier push, CI verte le 16 octobre 2026 (`setup-godot` accepte `4.7.2`).

## J1 — Moteur vérifiable

Chaque étape : règles lues, décision si système nouveau, implémentation par identifiants, tests nommés par identifiants, lint vert.

- [x] **1.1 Fondations** : `DuelState`, `PlayerState`, `Piece`, `CardInstance`, `StackEntry`, `ActiveEffect`, `PendingDecision`, `DuelConfig` (une valeur par règle PROVISOIRE), `BoardGeometry` (201.2), identifiants, `clone()` et son test par réflexion, bases `DuelIntent`, `DuelEvent`, `IntentRejected`. `DeepCompare`, `EventLog`, `DuelStateBuilder` repris du prototype et adaptés.
- [x] **1.2 Catalogue JSON** : `CardDefinition`, `HeroDefinition`, `EffectDefinition`, `TargetSpec`, `CatalogLoader`, `find_errors()`, test du catalogue (201.6, 202.1, 202.2). Forme du schéma : décision 0010 ; s'y ajoutent `Catalog` et `CatalogReader`.
- [ ] **1.3 Zones, Essence, tour** : 201, 203, 204 : préparation, Sources et Fonte, paiement `{incliner, recycler}`, mulligan simultané avec Écart, début de tour, pioche et fatigue (209.5), fin de tour sans déclencheur.
- [ ] **1.4 Pile et priorité** : 208 sans déclencheurs : annonce, 208.2.4, passes, bloc LIFO, retour au joueur actif ; 209.2 victoire après chaque effet ; `Concede`.
- [ ] **1.5 Actions et combat** : 205 et 206 : déploiement (annonce et résolution), action normale, déplacement du Hero, échecs, combat, égalité, Hero défenseur, auras lues avant l'avance, `ForceRules`.
- [ ] **1.6 Effets** : 207 et 202.3, 202.4 : Spells et vitesses, statiques, Gear, pouvoir du Hero, durées, cibles et validité, Contrecarrer, jetons.
- [ ] **1.7 Déclencheurs et mots-clés** : 207.3, 208.4, 210, 204.5 : file interne de faits, attente de fin de bloc, `ORDER_TRIGGERS`, `CHOOSE_TARGETS`, choix unique automatique (0004), « une fois par tour », Arrivée, Dernier souffle, Assaut, Rempart, Avant-poste.
- [ ] **1.8 Pendule** : 209.4 : `advance_clock`, `clock_owner`, temps écoulé, nul.
- [ ] **1.9 Cartes de test** : les 17 cartes et le Hero Capitaine en JSON (`/cards decks-de-test`).
- [ ] **1.10 Recette** : `test_rules_coverage.gd` sur `docs/ruleset/`, duels aléatoires avec oracle, déterminisme à graine fixe, `RandomLegalAgent`. **Sortie** : suite verte, chaque règle citée.

## J2 — Partie jouable

- [ ] 2.1 `AppEvents`, `DuelHost`, horloge réelle, machine à états de l'hôte ; journal et replay (test de non-régression).
- [ ] 2.2 Composants de vue et scènes d'essai ; `DuelSelection` testé sans scène.
- [ ] 2.3 Écran de duel : plateau, mains, Sources, pile, pendules, journal à l'écran, cases légales.
- [ ] 2.4 Relais entre joueurs locaux, préparation (decks, graine, mulligan), fin de partie ; scène principale.
- [ ] 2.5 `PlaytestRecorder` : fiche de relevé du protocole en CSV téléchargeable.
- [ ] 2.6 Export Web (preset, threads désactivés), job CI, GitHub Pages. **Sortie** : deux joueurs terminent un duel dans le navigateur, fiche produite.

## J3 — Premier playtest

- [ ] 20 parties selon `ruleset/70-playtest/protocole.md`, fiches automatiques, bilan contre le tableau des cibles et seuils, questions ouvertes du ruleset.

## J4 — IA et catalogue

- [ ] `GreedyAgent` (`clone()`, un coup, évaluation). Intégration de `50-cartes/`. Partie complète contre l'IA.

## Tenue du plan

- Cocher une étape terminée au sens de `CLAUDE.md` §8, puis mettre à jour « État actuel ».
- Aucune date prévue : seules comptent les étapes et leur ordre. Ce fichier est le seul plan.
