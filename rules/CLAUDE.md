# Moteur de duel — consignes locales

Complète le `CLAUDE.md` racine pour `rules/` ; décisions 0001, 0003, 0004, 0007, 0008, 0009, 0010, 0012, 0013, 0015, 0016, 0017, 0018, 0026, 0037, 0045, 0046 et 0057.

## Carte des modules (cible du jalon J1)

| Fichier | Chapitre | Rôle |
| --- | --- | --- |
| `duel_engine.gd` | — | Façade : `start_new_duel`, `start_from_state` (tests), `validate`, `submit`, `advance_clock`, `clock_owners`, `awaited_players`, requêtes en lecture pour la vue. Médiateur sans règle propre (`code-guidelines.md` §5) : après chaque intention, il enchaîne lui-même les étapes qui la suivent (effets en attente par `TriggerRules`, retour de la main par `StackRules`, suite de la fin du tour par `TurnRules`) et aiguille la résolution de chaque entrée de pile vers le module de son genre, que les modules ne déclenchent pas entre eux, et résout aussitôt, dans la même soumission, une pile qui contient une entrée sans réponse (208.7.13, décision 0046) ; un effet qui attend un choix (défausse, regard sur le deck) suspend le bloc, et la réponse le reprend (décision 0057) ; détail aux commentaires de `_settle` et `_resolve_stack` dans `duel_engine.gd`. |
| `zone_rules.gd` | 201 | zones, limite de main, appartenance, construction du deck, passage d'une pièce sur une case (`move_piece`) |
| `card_rules.gd` | 202 | Gear (annonce, attachement, remplacement, retour en main) |
| `essence_rules.gd` | 203 | paiement à l'annonce, incliner, recycler, Fonte, réserve d'Essence (203.6, 0026) |
| `preparation_rules.gd` | 204.1, 204.2 | préparation par `DuelSetup` (0012), mulligan simultané exécuté à la dernière réponse, joueur A puis B (0013, 0015) et Écart ; appelle `TurnRules` (premier tour, pioche), jamais l'inverse |
| `turn_rules.gd` | 204.3 à 204.5 | début de tour (204.3.8, réveil et redressement compris), pioche, fin de tour (204.5) |
| `action_rules.gd` | 205 | réveil des pièces (`wake_pieces`, 205.5), déploiement (annonce, résolution), action normale d'une pièce éveillée (205.5), déplacement du Hero, échecs, combat en attente (205.6 : naissance à la résolution, résolution selon le plateau du moment) |
| `combat_rules.gd` | 206 | comparaison, égalité, Hero défenseur, avance, auras lues avant l'avance |
| `spell_rules.gd` | 207.1 | Spells : annonce, résolution (les vitesses sont dans `StackRules.validate_speed`) ; appelle `EffectRules`, jamais l'inverse |
| `effect_rules.gd` | 207.4 à 207.6 | cibles et validité (filtres d'adjacence, pièces distinctes de l'échange, case de destination), effets à la résolution (Force à durée, destruction, jetons ; les effets de mouvement vont à `SwapRules`, `MoveRules` et `ReturnRules`), Contrecarrer (207.6, avec l'effet COUNTER) |
| `discard_rules.gd`, `look_rules.gd` | 212, 217 | effets de main (décision 0057) : défausser (`CardDiscardedFromHand`, attente `CHOOSE_DISCARD`, tirage au sort à l'expiration, 209.4.13), regarder le dessus du deck (`TopCardLooked`, attente `CHOOSE_TOP_CARD_PLACE`, 209.4.14), appelés par `EffectRules.resolve_effect` ; piocher réutilise `TurnRules.draw_cards`, réveiller (Unit ou Hero, cible ou pièce source) `ActionRules.wake_pieces`, aussi employée au réveil du début du tour |
| `swap_rules.gd`, `move_rules.gd`, `return_rules.gd` | 214, 215, 216 | application des effets échanger (`PiecesSwapped`), déplacer (`PieceMoved`) et renvoyer dans la main (`PieceReturnedToHand`), décision 0056 ; ni sommeil, ni arrivée, ni combat, ni destruction ; appelés par `EffectRules.resolve_effect`, qui juge leurs cibles (207.5) |
| `effect_context.gd` | 207.4, 207.5 | état, entrée de pile, effet et événements de l'effet en cours d'application, passés aux fonctions d'`EffectRules` ; jamais dans l'état |
| `order_rules.gd` | 211, 208.1.12 | Ordre du Hero (0055) : annonce (`AnnounceOrder`, le Hero s'endort, coût payé par `EssenceRules`, cibles jugées par `EffectRules`, vitesse par `StackRules.validate_speed`) et résolution de l'entrée `ORDER` par `EffectRules.resolve_all` ; n'est appelé que par `DuelEngine` |
| `trigger_rules.gd` | 207.3, 208.4 | effets déclenchés (0017) : attente, ordre d'ajout (`ORDER_TRIGGERS`), cibles (`CHOOSE_TARGETS`, pièces et cases candidates d'un déplacement, décision 0056), choix unique automatique (0004), « une fois par tour », résolution ; étiquette « sans réponse » recopiée de l'annonce ou de l'entrée en cours (208.7.8 à 208.7.11, `DuelState.triggers_allow_response`) ; un combat en attente (205.6) attend dans la même liste et compte comme un effet de l'attaquant (205.6.6) |
| `stack_rules.gd` | 208 | annonce, vitesses des annonces (`validate_speed`, 207.1.3 à 207.1.6, 211.2.4 à 211.2.7), priorité (208.2.4, aucune pour une entrée sans réponse, 208.7.12), passe (208.3.1), entrée du sommet et fin de sa résolution (208.3.2 ; `DuelState.resolving_entry` et le rang du prochain effet, décision 0057), pose d'une attente (`request_decision`, qui remet aussi à neuf le temps de réponse des joueurs attendus, 209.4.6 ; `PendingDecision.for_resolution` fabrique celles des choix de résolution), retour au joueur actif (208.5.1) ; n'appelle aucun autre module, la boucle de résolution est dans `DuelEngine` |
| `state_check_rules.gd` | 209 | Force plancher 0, victoire après chaque effet, abandon, inactivité (209.2.10), temps de tour et de réponse (209.4), fatigue |
| `keyword_rules.gd` | 210 | texte de règle de chaque mot-clé |
| `force_rules.gd` | 206.5, 209.1 | Force actuelle calculée à la demande, jamais stockée |
| `board_geometry.gd` | 201.2, 205 | adjacence, rangées, zones de déploiement, notation A1 à E5 |
| `duel_state.gd`, `player_state.gd`, `piece.gd`, `card_instance.gd`, `stack_entry.gd`, `active_effect.gd`, `pending_decision.gd` | — | État mutable, `clone()` complet |
| `duel_config.gd` | règles PROVISOIRE | une valeur par règle PROVISOIRE, lecture seule |
| `catalog/` | 202 | `CardDefinition`, `HeroDefinition` (passif facultatif, effets déclenchés, Ordres), `HeroOrder`, `EffectDefinition`, `TargetSpec`, chacun avec `find_errors()` ; `Catalog` (résolution par id, contrôle de deck 201.6), `CatalogLoader` (JSON), `CatalogReader` (lecture typée), `JsonObjectFiles` (fichiers JSON) ; `DeckList` et `DeckLoader`, decks de `data/decks/` (0037) |
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

Le champ **et** sa copie dans `clone()` de la même classe, puis une valeur non par défaut dans `_build_full_state()` du test de clonage : le test échoue sinon. Un enum enregistré dans un fichier (journal, JSON, `.tres`, CSV) prend ses nouvelles valeurs à la fin et ne se réordonne pas ; une valeur devenue inutile d'un enum non enregistré se supprime (décision 0047).

## Invariants à ne pas casser

- `StackEntry.allows_response` est posé à la naissance de l'entrée (annonce : son genre et le plateau à l'annonce, 208.7.1 à 208.7.6 ; effet déclenché : `DuelState.triggers_allow_response`, que `add_to_stack`, la résolution de chaque entrée, `start_turn` et `apply_end_turn` fixent) ; une pile qui contient une entrée sans réponse ne reste jamais en attente d'une passe (elle attend seulement un choix d'ordre ou de cibles, décision 0009).
- `DuelState.resolving_entry` n'est non nul que pendant une résolution suspendue par un choix (`pending_decision` non null), ou dans une partie arrêtée (209.2.2) ; la carte d'un Spell en cours de résolution y reste, comptée par l'oracle. Pendant ce choix le temps de tour du joueur actif est en pause et son temps de réponse s'écoule (209.4.7c, 209.4.7d).
- Aléa, heure et Node : règle du `CLAUDE.md` racine §3 ; concrètement, jamais `randi()` ni `Array.shuffle()`.
- Une `CardInstance` est dans une seule zone à la fois : la déplacer, jamais la copier. Une pièce qui revient sur le plateau reçoit un nouveau `piece_id`.
- La Force actuelle se calcule par `ForceRules`, jamais ne se stocke.
- Phase `ENDED` ⇒ toute intention refusée ; `state.pending_decision` non null ⇒ seule l'intention qui y répond est acceptée, et `Concede` (209.2.5 : à tout moment).
- Un Hero ne perd de PV que par `StateCheckRules.lose_health()` ou `apply_fatigue()`, qui vérifient la victoire avec la raison de fin (209.2.1, décision 0040).
- Le temps de tour et le temps de réponse ne s'écoulent que par `advance_clock()`, jamais pendant un `submit()` ; ils ne se remettent à neuf que par `TurnRules.start_turn`, `StackRules.add_to_stack` (entrée avec réponse seulement) et `StackRules.request_decision` (nouvelle attente).
- Les modules ne lisent que `state`, le catalogue compris par `state.catalog`, en lecture seule (0016) ; aucune injection, aucun accès à la vue.
