# Tests — consignes locales

Complète le `CLAUDE.md` racine pour `tests/`. GdUnit4 6.2.1 ; commandes dans `tools/run_tests.sh`.

## Nommage et portée

- Une suite par chapitre ou par contrat : `test_205_actions.gd`, `test_208_stack.gd`, `test_duel_state_clone.gd`.
- Chaque test de règle porte l'identifiant : `test_206_3_6_tie_destroys_both`. Un test sans identifiant vérifie un contrat de décision.
- Couverture (J1) : `test_rules_coverage.gd` lit `docs/ruleset/20-regles-completes/*.md` et exige, pour chaque règle `[ACTÉ]` ou `[PROVISOIRE]` non supprimée, un test à son nom ou une entrée justifiée de `RULES_WITHOUT_OWN_TEST` (règle de structure, ou vérifiée sous une autre règle, tests nommés). Il exige aussi que chaque `RejectReason` hors `NONE` soit cité par un test.
- Duels aléatoires (J1) : graine fixe, intentions légales quelconques, oracle qui recalcule les conditions du ruleset sans `validate()`, invariants d'état après chaque entrée ; un écart se rapporte avec graine, pas et entrée.
- Logique de vue : `DuelSelection` et les fonctions statiques des vues se testent sans scène ; aucune suite n'instancie de scène, `--ignoreHeadlessMode` reste sûr.
- L'en-tête d'une suite nomme l'édition du ruleset et la décision suivies.
- Ne jamais résoudre dans un test un `kind` que le moteur ne code pas encore.

## Outils de `tests/support/` (repris du prototype au J1)

| Outil | Usage |
| --- | --- |
| `DuelStateBuilder` | état construit à la main ; `cell("B2")` ; `add_to_deck/hand/discard`, `place_piece`, `push_*` qui simulent une annonce déjà faite ; `place_unit_in(state, …)` pour une pièce arrivée sur un état déjà démarré ; un builder sert une fois |
| `TestCatalog` | cartes et decks de `docs/ruleset/70-playtest/decks-de-test.md` chargés depuis `data/cards/` |
| `EventLog` | `describe(events)` → `["TurnEnded:A", "TurnStarted:B"]` ; `rejection_reason(events)` |
| `SetupSamples` | catalogue en mémoire (dix Units, Hero d'essai) et `DuelSetup` valide pour `DuelEngine.start_new_duel` |
| `DeepCompare` | `find_clone_defects(a, b)` par réflexion ; `find_fields_never_set` protège le test de `clone()` |

## Motifs

- **Acceptée** : `assert_array(EventLog.describe(events)).contains_exactly(expected)`, puis les champs d'état touchés.
- **Refusée** : `snapshot := state.clone()` ; raison attendue ; `DeepCompare.find_clone_defects(snapshot, state)` vide.
- **Valeurs PROVISOIRE** : recopier la valeur du ruleset en constante commentée (`HAND_LIMIT = 7  # 201.3.4`) plutôt que lire `DuelConfig`, afin que le test contrôle la configuration.
- **Déterminisme** : deux moteurs, même graine, mêmes intentions ; états et événements égaux par `DeepCompare`.
- `before_test()` pour les définitions en mémoire ; `before()` pour charger le catalogue une fois par suite.
