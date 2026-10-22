# Moteur de duel — consignes locales

Complète le `CLAUDE.md` racine pour `rules/` ; décisions 0001, 0003, 0004, 0007, 0008, 0009, 0010, 0012, 0013, 0015, 0016, 0017, 0018, 0026 et 0037.

## Carte des modules (cible du jalon J1)

| Fichier | Chapitre | Rôle |
| --- | --- | --- |
| `duel_engine.gd` | — | Façade : `start_new_duel`, `start_from_state` (tests), `validate`, `submit`, `advance_clock`, `clock_owners`, `awaited_players`, requêtes en lecture pour la vue. Médiateur sans règle propre (`code-guidelines.md` §5) : après chaque intention, il enchaîne lui-même les étapes qui la suivent (effets en attente par `TriggerRules`, retour de la main par `StackRules`, suite de la fin du tour par `TurnRules`) et aiguille la résolution de chaque entrée de pile vers le module de son genre, que les modules ne déclenchent pas entre eux ; détail aux commentaires de `_settle` et `_resolve_stack` dans `duel_engine.gd`. |
| `zone_rules.gd` | 201 | zones, limite de main, appartenance, construction du deck, passage d'une pièce sur une case (`move_piece`) |
| `card_rules.gd` | 202 | Gear (annonce, attachement, remplacement, retour en main), pouvoir du Hero |
| `essence_rules.gd` | 203 | paiement à l'annonce, incliner, recycler, Fonte, réserve d'Essence (203.6, 0026) |
| `preparation_rules.gd` | 204.1, 204.2 | préparation par `DuelSetup` (0012), mulligan simultané exécuté à la dernière réponse, joueur A puis B (0013, 0015) et Écart ; appelle `TurnRules` (premier tour, pioche), jamais l'inverse |
| `turn_rules.gd` | 204.3 à 204.5 | début de tour (204.3.8, réveil et redressement compris), pioche, fin de tour (204.5) |
| `action_rules.gd` | 205 | déploiement (annonce, résolution), action normale d'une pièce éveillée (205.5), déplacement du Hero, échecs |
| `combat_rules.gd` | 206 | comparaison, égalité, Hero défenseur, avance, auras lues avant l'avance |
| `spell_rules.gd` | 207.1 | Spells : vitesses, annonce, résolution ; appelle `EffectRules`, jamais l'inverse |
| `effect_rules.gd` | 207.4 à 207.6 | cibles et validité, effets à la résolution (Force à durée, destruction, jetons), Contrecarrer (207.6, avec l'effet COUNTER) |
| `effect_context.gd` | 207.4, 207.5 | état, entrée de pile, effet et événements de l'effet en cours d'application, passés aux fonctions d'`EffectRules` ; jamais dans l'état |
| `trigger_rules.gd` | 207.3, 208.4 | effets déclenchés (0017) : attente, ordre d'ajout (`ORDER_TRIGGERS`), cibles (`CHOOSE_TARGETS`), choix unique automatique (0004), « une fois par tour », résolution |
| `stack_rules.gd` | 208 | annonce, priorité (208.2.4), passe (208.3.1), entrée du sommet et fin de sa résolution (208.3.2), retour au joueur actif (208.5.1) ; n'appelle aucun autre module, la boucle de résolution est dans `DuelEngine` |
| `state_check_rules.gd` | 209 | Force plancher 0, victoire après chaque effet, abandon, pendule, fatigue |
| `keyword_rules.gd` | 210 | texte de règle de chaque mot-clé |
| `force_rules.gd` | 206.5, 209.1 | Force actuelle calculée à la demande, jamais stockée |
| `board_geometry.gd` | 201.2, 205 | adjacence, rangées, zones de déploiement, notation A1 à E5 |
| `duel_state.gd`, `player_state.gd`, `piece.gd`, `card_instance.gd`, `stack_entry.gd`, `active_effect.gd`, `pending_decision.gd` | — | État mutable, `clone()` complet |
| `duel_config.gd` | règles PROVISOIRE | une valeur par règle PROVISOIRE, lecture seule |
| `catalog/` | 202 | `CardDefinition`, `HeroDefinition`, `EffectDefinition`, `TargetSpec`, chacun avec `find_errors()` ; `Catalog` (résolution par id, contrôle de deck 201.6), `CatalogLoader` (JSON), `CatalogReader` (lecture typée), `JsonObjectFiles` (fichiers JSON) ; `DeckList` et `DeckLoader`, decks de `data/decks/` (0037) |
| `intents/`, `events/` | — | une classe par intention et par événement ; bases `DuelIntent`, `DuelEvent`, `PlayerEvent` |

## Ajouter une intention

1. Classe dans `intents/`, `extends DuelIntent`, documentée par ses identifiants ; champs typés ; cartes, pièces et entrées de pile désignées par identifiant entier, cases par `Vector2i` ; paiement par `EssencePayment` (0003).
2. Événements dans `events/`, un par fait observable.
3. Raisons de refus : valeurs ajoutées **à la fin** de `IntentRejected.RejectReason`, commentées par leur identifiant.
4. Dans le module du chapitre : `validate_*(state, intent) -> RejectReason`, pur, puis `apply_*(state, intent, events)` qui suppose l'intention valide.
5. Aiguillage dans `DuelEngine.validate()` et `_apply()`.
6. Tests : acceptée avec sa séquence d'événements exacte ; refusée hors phase et pour chaque raison, état inchangé (`DeepCompare`).

## Ajouter un `kind` d'effet

1. Valeur à la fin de `EffectKind` ; champs exigés déclarés dans `EffectDefinition.find_errors()` (timings admis, cible attendue, paramètres) ; test dans `tests/test_catalog_effects.gd`.
2. Code et tests dans le module du chapitre, avant toute carte JSON (règle racine, 0002). Les cibles exigées passent par `TargetSpec`, validées à l'ajout à la pile et à la résolution (207.5).
3. Carte JSON ensuite ; le test du catalogue passe.

## Ajouter un champ d'état

Le champ **et** sa copie dans `clone()` de la même classe, puis une valeur non par défaut dans `_build_full_state()` du test de clonage : le test échoue sinon. Un enum porté par l'état est journalisable : ajouter à la fin.

## Invariants à ne pas casser

- Aléa, heure et Node : règle du `CLAUDE.md` racine §3 ; concrètement, jamais `randi()` ni `Array.shuffle()`.
- Une `CardInstance` est dans une seule zone à la fois : la déplacer, jamais la copier. Une pièce qui revient sur le plateau reçoit un nouveau `piece_id`.
- La Force actuelle se calcule par `ForceRules`, jamais ne se stocke.
- Phase `ENDED` ⇒ toute intention refusée ; `state.pending_decision` non null ⇒ seule l'intention qui y répond est acceptée, et `Concede` (209.2.5 : à tout moment).
- Un Hero ne perd de PV que par `StateCheckRules.lose_health()` ou `apply_fatigue()`, qui vérifient la victoire avec la raison de fin (209.2.1, décision 0040).
- Les pendules ne bougent que par `advance_clock()`, jamais pendant un `submit()`.
- Les modules ne lisent que `state`, le catalogue compris par `state.catalog`, en lecture seule (0016) ; aucune injection, aucun accès à la vue.
