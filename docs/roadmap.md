# Plan de développement

> **Rôle** : plan unique du projet : périmètre, jalons, étapes et état. Les règles font foi dans [ruleset/](ruleset/README.md) ; l'architecture dans [decisions/](decisions/).

**État actuel (16 octobre 2026)** : jalon J0 amorcé : dépôt créé, `project.godot` Godot 4.7.2 GL Compatibility, GdUnit4 6.2.1 et hook repris du prototype et vérifiés en headless (smoke test vert, 14 tests du hook verts), gdtoolkit 4.5.0 dans `.venv`, ruleset 0.28 synchronisé, consignes, 7 agents, 7 skills, décisions 0001 à 0007, CI écrite mais non exécutée (aucun remote). Prochaine action : créer le remote GitHub et pousser pour valider la CI, puis J1 étape 1.1.

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
- [ ] Remote GitHub créé, premier push, CI verte (vérifier la chaîne de version de `setup-godot`).

## J1 — Moteur vérifiable

Chaque étape : règles lues, décision si système nouveau, implémentation par identifiants, tests nommés par identifiants, lint vert.

- [ ] **1.1 Fondations** : `DuelState`, `PlayerState`, `Piece`, `CardInstance`, `StackEntry`, `ActiveEffect`, `PendingDecision`, `DuelConfig` (une valeur par règle PROVISOIRE), `BoardGeometry` (201.2), identifiants, `clone()` et son test par réflexion, bases `DuelIntent`, `DuelEvent`, `IntentRejected`. `DeepCompare`, `EventLog`, `DuelStateBuilder` repris du prototype et adaptés.
- [ ] **1.2 Catalogue JSON** : `CardDefinition`, `HeroDefinition`, `EffectDefinition`, `TargetSpec`, `CatalogLoader`, `find_errors()`, test du catalogue (201.6, 202.1, 202.2).
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

- [ ] 20 parties selon `ruleset/70-playtest/protocole.md`, fiches automatiques, bilan contre le tableau des cibles et seuils, questions pour `tcg-ruleset`.

## J4 — IA et catalogue

- [ ] `GreedyAgent` (`clone()`, un coup, évaluation). Intégration de `50-cartes/`. Partie complète contre l'IA.

## Tenue du plan

- Cocher une étape terminée au sens de `CLAUDE.md` §8, puis mettre à jour « État actuel ».
- Aucune date prévue : seules comptent les étapes et leur ordre. Ce fichier est le seul plan.
