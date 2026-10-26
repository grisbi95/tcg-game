# Tests — consignes locales

Complète le `CLAUDE.md` racine pour `tests/` ; commandes dans `CLAUDE.md` §7.

## Nommage et portée

- Une suite par chapitre ou par contrat : `test_205_deploy.gd`, `test_208_stack.gd`, `test_duel_state_clone.gd`.
- Identifiant sur chaque test de règle (racine) ; un test sans identifiant vérifie un contrat de décision, comme `test_duel_state_clone.gd`.
- Couverture (J1) : `test_rules_coverage.gd` lit `docs/ruleset/20-regles-completes/*.md` et exige, pour chaque règle `[ACTÉ]` ou `[PROVISOIRE]` non supprimée, un test à son nom ou une entrée justifiée de `RULES_WITHOUT_OWN_TEST` (règle de structure, ou vérifiée sous une autre règle, tests nommés). Pendant le jalon J2c (décision 0054), une règle consignée mais pas encore codée figure dans `RULES_AWAITING_IMPLEMENTATION` avec son étape (`c.1` à `c.5`) ; l'étape qui la code retire la ligne en écrivant son test. Il exige aussi que chaque `RejectReason` hors `NONE` soit cité par un test ; une raison que le moteur ne produit plus se supprime de l'enum.
- Duels aléatoires (J1) : graine fixe, intentions légales quelconques, oracle qui recalcule les conditions du ruleset sans `validate()`, invariants d'état après chaque entrée ; un écart se rapporte avec graine, pas et entrée.
- Logique de vue : `DuelSelection` et les fonctions statiques des vues se testent sans scène ; aucune suite n'instancie de scène (`test_event_player.gd` ajoute un `Node` nu à l'arbre, pas une scène), `--ignoreHeadlessMode` reste sûr.
- L'en-tête d'une suite de règles nomme l'édition du ruleset et la décision suivies ; une décision de design du ruleset se cite « décision de design 0197 » ou « décision 0197 du ruleset », jamais « décision 0197 » seul.
- Ne jamais résoudre dans un test un `kind` que le moteur ne code pas encore.
- Relevé de playtest (2.5, décision 0042) : `test_playtest_recorder.gd` lit la fiche de journaux rejoués (fixture et `PlaytestScenarios`), un test par mesure nommé par la règle que la mesure vise ; `test_playtest_sheet.gd` contrôle le CSV et les textes de fin.
- Non-régression (J2, décision 0022) : `test_duel_journal.gd` rejoue `tests/fixtures/replay_random_duel.journal.json` et compare son empreinte. Un écart voulu (règle modifiée) se régénère par `"$GODOT_BIN" --headless --path . -s tools/record_replay_fixture.gd`, en le disant dans le rapport ; un écart non voulu est un bogue.

## Outils de `tests/support/` (repris du prototype au J1)

| Outil | Usage |
| --- | --- |
| `DuelStateBuilder` | état construit à la main ; `cell("B2")` ; `add_to_deck/hand/discard`, `place_piece`, `push_*` qui simulent une annonce déjà faite (`push_deploy` et `push_normal_action` prennent l'étiquette `allows_response`, vraie par défaut ; fausse, le moteur résout l'entrée à sa prochaine soumission) ; `place_unit_in(state, …)` pour une pièce arrivée sur un état déjà démarré ; un builder sert une fois ; pièces et Heroes placés éveillés par défaut, `with_piece_awake(piece_id, false)` pour une pièce endormie (205.5) |
| `TestCatalog` | cartes et decks de `docs/ruleset/70-playtest/decks-de-test.md` chargés depuis `data/cards/` et `data/decks/` (0037) |
| `EventLog` | `describe(events)` → `["TurnEnded:A", "TurnStarted:B"]` ; `rejection_reason(events)` |
| `SetupSamples` | catalogue en mémoire (dix Units, Hero d'essai) et `DuelSetup` valide pour `DuelEngine.start_new_duel` |
| `DeepCompare` | `find_clone_defects(a, b)` par réflexion ; `find_fields_never_set` protège le test de `clone()` |
| `ManualClock` | horloge de `DuelHost` dont le temps n'avance que par `advance(msec)` (décision 0021) |
| `ReplayFingerprint` | empreinte d'un duel rejoué : événements et état final par réflexion, SHA-256, `find_differences` |
| `ReplayFixture` | duel de non-régression (décision 0022) : `play()`, `fingerprint_of(journal)`, fichiers de `tests/fixtures/` |
| `ResponseWindowProbe` | fenêtre de réponse de `DuelHost` laissée ouverte longtemps sans geste (208.6.2, décision 0029) : ouverte à l'ouverture et après l'attente, événements ; `count_castable` pour les Réactions jouables |
| `ResponseWindowSamples` | catalogues d'essai (Réaction sans effet, Héraut), carte ajoutée à la main d'un duel démarré, Réaction annoncée par A (avec l'attaque, seul moyen d'ouvrir la fenêtre de B, 208.7), déploiement de A et mulligans passés par l'hôte, nombre d'intentions journalisées d'un hôte |
| `CatalogSamples` | dictionnaires JSON minimaux et valides pour les tests du catalogue (0002, 0010) |
| `DuelChecks` | contrôles partagés des suites qui passent par `DuelEngine` : écarts d'une soumission refusée (raison, état modifié), `pass_once`, `pass_until_stack_empty` (entrée posée à la main, puis son combat en attente), `is_hero_placed`, `card_ids` |
| `DuelOracle` | oracle des duels aléatoires (1.10) : recalcule depuis l'état, sans `validate()`, conditions du ruleset et invariants |
| `HostDriver` | fait jouer un `DuelHost` sans scène (0020) : confirme l'affichage, avance `ManualClock`, appelle `tick()` |
| `TriggerSamples` | catalogue en mémoire des suites d'effets déclenchés (207.3, 208.4, 210.3, 204.5.3) |
| `OrderSamples` | catalogue en mémoire des suites de l'Ordre du Hero (211, 0055) : dix Units, `UNIT`, Spell `COUNTER_SPELL`, Hero d'essai à deux Ordres (Action sans coût à cible, Réaction à coût qui crée un jeton) et un effet déclenché en fin de tour, variante « une fois par tour » |
| `MovementSamples` | catalogue en mémoire des suites de mouvement (214 à 216, décision 0056) : reprend `TriggerSamples`, ajoute un Spell et une Unit à Arrivée par kind (échanger, déplacer, renvoyer), un Spell d'échange limité aux Units adjacentes au Hero, le Gear d'essai ; `cast` et `choose` fabriquent `CastSpell` et `ChooseTargets` avec pièces et cases |
| `HumanDuelDriver` | deux humains sur un `DuelHost` à `ManualClock`, sans scène (0020, 0021) : chaque intention est suivie de la confirmation d'affichage et du relais ; `end_turn`, `deploy` (sans réponse), `move` (l'adversaire passe si c'est une attaque), `pass_priority`, `wait`, `record_sheet` ; sert au relevé de playtest (0042) |
| `PlaytestScenarios` | duels de deux humains joués par `HumanDuelDriver` sur le catalogue d'essai (tours sans action, déploiement, économie, réponse, marche jusqu'au combat, Martyrs, petit deck), dont les tests du relevé lisent la fiche |
| `LoopbackConnection` | deux `RelayConnection` appariées sans réseau (0049, 0050) : messages relus en JSON, fermer l'une ferme l'autre comme un départ ; sert à `test_remote_session.gd` |
| `ColumnSpy`, `PreviewSpy` | sous-classes sans scène de `DuelColumnView` et `HoverPreview`, jamais ajoutées à l'arbre, qui enregistrent leurs appels, pour `DuelCenterPresenter` et `DuelPreviewer` |

## Motifs

- **Acceptée** : `assert_array(EventLog.describe(events)).contains_exactly(expected)`, puis les champs d'état touchés.
- **Refusée** : `snapshot := state.clone()` ; raison attendue ; `DeepCompare.find_clone_defects(snapshot, state)` vide.
- **Valeurs PROVISOIRE** : recopier la valeur du ruleset en constante commentée (`HAND_LIMIT = 7  # 201.3.4`) plutôt que lire `DuelConfig`, afin que le test contrôle la configuration.
- **Déterminisme** : deux moteurs, même graine, mêmes intentions ; états et événements égaux par `DeepCompare`.
- `before_test()` pour les définitions en mémoire ; `before()` pour charger le catalogue une fois par suite.
