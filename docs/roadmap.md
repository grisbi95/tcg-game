# Plan de développement

> **Rôle** : plan unique du projet : périmètre, jalons, étapes et état. Les règles font foi dans [ruleset/](ruleset/README.md) ; l'architecture dans [decisions/](decisions/).

**État actuel (17 octobre 2026)** : jalon J0 terminé ; J1 étapes 1.1 à 1.4 terminées. 1.1 et 1.2 fusionnées par la PR 1 ; 1.3 et la fusion du ruleset (décision 0014) par la PR 3 ; 1.4 par la PR 4. Étape 1.5 en cours sur `feat/1.5-actions` : décision 0016 (catalogue en lecture seule dans l'état) ; ruleset 0.31 (Q-080 et Q-081 tranchées : 205.2.6 et 205.3.3, case visée à l'annonce de l'action normale) ; bloc 1 fait (catalogue dans `DuelState.catalog`, `ForceRules` 209.1 et 206.5.1, `CombatRules` 206 : comparaison, égalité selon `DuelConfig`, destruction vers la défausse, Hero défenseur ; `test_209_1_force.gd`, `test_206_combat.gd`) ; bloc 2 fait (`ActionRules` : intention `DeployCard`, annonce payée et posée sur la pile, résolution sur case libre, en attaquant l'ennemi ou retour en main ou défausse, 205.1 ; `test_205_deploy.gd`) ; bloc 3 fait (intention `TakeNormalAction` : annonce sans Essence, comptée dès l'annonce, case libre ou ennemie pour une Unit (205.2.6), libre et dans les deux rangées proches pour le Hero (205.3.2, 205.3.3) ; résolution : déplacement, attaque, ou échec 205.4 ; `test_205_normal_action.gd`) ; contrôle du typage `tools/check_typing.sh` ajouté à la CI ; 357 tests verts, typage propre. Ruleset dans `docs/ruleset/`, édition 0.31, aucune question ouverte ; décisions du projet 0001 à 0016. Moteur : `DuelEngine` (façade), `ZoneRules` (201), `EssenceRules` (203), `TurnRules` (204), `StackRules` (208 sans déclencheurs : `add_to_stack`, `PassPriority`, résolution d'un bloc, retour au joueur actif), `StateCheckRules` (209.2 victoire et partie nulle par `lose_health`, seule voie de perte de PV ; abandon `Concede` ; 209.5 fatigue) ; 282 tests verts, lint propre. Prochaine action : clore 1.5 (`/close-step 1.5`), puis étape 1.6 (effets, Spells, Gear, pouvoir du Hero). À reprendre : une entrée résolue quitte la pile sans effet ni zone d'arrivée tant que son genre n'est pas codé (Spell, pouvoir du Hero, Gear : 1.6) ; Avant-poste (205.1.2a) vient avec les mots-clés en 1.7 ; le test de 209.2.3 part d'un Hero déjà à 0 PV, à réécrire avec un Spell en 1.6 ; la pendule ne tourne pas (1.8) ; les conventions de 1.3 (compteurs par tour remis à zéro pour les deux joueurs, pile vide pour terminer son tour) ne sont écrites que dans le code ; le protocole de playtest impose le premier joueur d'avance, à préciser avant J3 pour respecter 204.1.16.

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
- [x] **1.3 Zones, Essence, tour** : 201, 203, 204 : préparation, Sources et Fonte, paiement `{incliner, recycler}`, mulligan simultané avec Écart, début de tour, pioche et fatigue (209.5), fin de tour sans déclencheur.
- [x] **1.4 Pile et priorité** : 208 sans déclencheurs : annonce, 208.2.4, passes, bloc LIFO, retour au joueur actif ; 209.2 victoire après chaque effet ; `Concede`.
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
