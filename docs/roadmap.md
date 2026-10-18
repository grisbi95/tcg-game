# Plan de développement

> **Rôle** : plan unique du projet : périmètre, jalons, étapes et état. Les règles font foi dans [ruleset/](ruleset/README.md) ; l'architecture dans [decisions/](decisions/).

**État actuel (18 octobre 2026)** : jalons J0 et J1 terminés (PR 1 à 10) ; 2.1 fusionnée par la PR 11 ; étape 2.2 terminée, PR 12 ouverte ; sur `feat/stack-fast-priority`, résolution à la première passe (hors étape, constat de playtest). Ruleset dans `docs/ruleset/`, édition 0.36 (Q-096 : une seule passe résout la pile, le propriétaire du sommet est considéré comme ayant passé, 208.3.1a, décision 0197 ; fenêtre de réponse de 2 s à l'écran, pendule qui tourne, 208.6, décision 0198 ; Q-089 à Q-095 : réserve d'Essence remplie pendant son tour en inclinant ou recyclant ses Sources, quand on peut agir, sans passer par la pile, publique, perdue à 204.5.7a ; paiement à l'annonce pendant le tour adverse ; mesure de l'Essence perdue au protocole de playtest), aucune question ouverte ; décisions du projet 0001 à 0026. Moteur : réserve d'Essence (`ProduceEssence`, `PlayerState.essence_reserve`, `EssenceRules.pay_cost`, décision 0026), requête `DuelEngine.current_force` pour la vue ; une passe résout toute la pile (`consecutive_passes` supprimé). Application (2.1) : `AppEvents`, `DuelHost`, horloge réelle, journal et replay de non-régression. Vue (2.2) : `DuelSelection` pas à pas avec `SelectionCandidates`, `SelectionSnapshot`, `SelectionTarget` (0023, 0024), testée sans scène ; huit composants sobres (0025) `CardView`, `PieceView`, `CellView`, `SourcesView`, `ClockView`, `StackView`, `HoverPreview`, `LogView`, thème unique `ui/theme/duel_theme.tres` et `DuelPalette`, textes `EventText` et `CardText` ; une scène d'essai par composant et un bac à sable `ui/components/_try/try_duel_sandbox.tscn` où l'on joue les deux joueurs sur un écran (outil de développement, sans relais ni animation), vérifiés dans l'éditeur. 698 tests verts, lint propre, typage contrôlé. Prochaine action : fusion de la PR 12 puis PR de la première passe, puis étape 2.3 (écran de duel, avec la fenêtre de réponse). À reprendre : la Force d'un Hero vaut 0 par convention (202.3.9) et le catalogue refuse un effet de Force ou de destruction visant un Hero, faute de règle ; choisir deux fois la même cible n'est pas tranché (aucune carte à plusieurs cibles) ; le pouvoir d'un Hero à plusieurs cibles opposerait 207.5.17 et 207.5.10 ; l'égalité ne connaît que l'option A de la décision 0053 du ruleset ; une Unit qui se déploie en attaquant n'a pas de case pendant le combat ; une carte qui porte « une fois par tour » et plusieurs effets déclenchés est refusée par le catalogue (207.3.5, 207.3.7) ; aucun déclencheur ne réagit à une annonce ni au début du tour, et un jeton ne déclenche rien (règles justifiées dans `RULES_WITHOUT_OWN_TEST`) ; `ActiveEffect.effect_kind` est une StringName alors qu'un enum existe ; le test de 209.2.3 part d'un Hero déjà à 0 PV ; 204.5.5 et 208.4.5 disent encore « les joueurs peuvent répondre » aux effets déclenchés, sens restreint par 208.3.1a, à relire ; `RandomLegalAgent` épuise ses Sources en quelques centaines de pas et des duels aléatoires ne finissent jamais sans la pendule ; rien ne garantit que la suite tire `OrderTriggers` ; les conventions de 1.3 ne sont écrites que dans le code ; le protocole de playtest impose le premier joueur d'avance, à préciser avant J3 pour respecter 204.1.16 ; deux pendules ne tournent plus jamais ensemble : la branche de `advance_clock` pour plusieurs pendules (nulle au temps, première à 0 qui arrête les autres) n'a plus de test (décision de design 0189) ; un agent qui ne propose aucune intention légale laisse `DuelHost` en AWAITING_AI avec une erreur à chaque image, jusqu'à la fin de sa pendule ; à deux humains, le mulligan se fait A puis B sur le même écran (204.2.2 « en même temps »), à relire avant J3 ; `RandomLegalAgent` ne remplit jamais sa réserve d'Essence (il paie à l'annonce, 203.6.5) : la réserve n'est couverte que par ses tests dédiés ; `DuelSelection` ne gère qu'une cible par annonce ; le paiement préparé pendant le tour adverse ignore la limite de recyclage 203.4.2 (illimitée aujourd'hui) ; le bac à sable montre les deux mains et redessine tout à chaque changement ; `DuelViewModel` (masquer main, deck et Écart adverses) et `EventPlayer` restent à faire à l'étape 2.3.

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
- [x] **1.5 Actions et combat** : 205 et 206 : déploiement (annonce et résolution), action normale, déplacement du Hero, échecs, combat, égalité, Hero défenseur, auras lues avant l'avance, `ForceRules`.
- [x] **1.6 Effets** : 207 et 202.3, 202.4 : Spells et vitesses, statiques, Gear, pouvoir du Hero, durées, cibles et validité, Contrecarrer, jetons.
- [x] **1.7 Déclencheurs et mots-clés** : 207.3, 208.4, 210, 204.5 : liste d'attente des effets déclenchés (décision 0017), attente de fin de bloc, `ORDER_TRIGGERS`, `CHOOSE_TARGETS`, choix unique automatique (0004), « une fois par tour », Arrivée, Dernier souffle, Assaut, Rempart, Avant-poste ; Q-085 du ruleset (205.1.2b).
- [x] **1.8 Pendule** : 209.4 : `advance_clock`, `clock_owners` (les deux pendules pendant le mulligan), temps écoulé, nul (décision 0018).
- [x] **1.9 Cartes de test** : les 17 cartes et le Hero Capitaine en JSON (`/cards decks-de-test`), `data/cards/test_deck.json`, contrôlés carte par carte par `test_test_deck.gd`.
- [x] **1.10 Recette** : `test_rules_coverage.gd` sur `docs/ruleset/`, duels aléatoires avec oracle, déterminisme à graine fixe, `RandomLegalAgent`. **Sortie** : suite verte, chaque règle citée.

## J2 — Partie jouable

- [x] 2.1 `AppEvents`, `DuelHost`, horloge réelle, machine à états de l'hôte ; journal et replay (test de non-régression). Décisions 0020 à 0022.
- [x] 2.2 Composants de vue et scènes d'essai ; `DuelSelection` testé sans scène. Décisions 0023 à 0026.
- [ ] 2.3 Écran de duel : plateau, mains, Sources, pile, pendules, journal à l'écran, cases légales ; fenêtre de réponse de 2 s (208.6, décision de design 0198), décision du projet à prendre sur sa place (hôte ou vue).
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
