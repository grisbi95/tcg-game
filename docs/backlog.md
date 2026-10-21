# Backlog des dettes techniques

> **Rôle** : seul propriétaire des dettes techniques (décision 0038) : une ligne par dette, sa référence (règle ou décision), sa priorité et sa cible. Une dette réglée se supprime. Les questions de règles vont dans [ruleset/02-questions-ouvertes.md](ruleset/02-questions-ouvertes.md), les mesures de playtest dans [ruleset/70-playtest/protocole.md](ruleset/70-playtest/protocole.md), le plan dans [roadmap.md](roadmap.md).

Priorité : **haute** = écart au ruleset ou défaut visible en partie ; **moyenne** = manque qui bloquera une étape nommée ; **basse** = propreté.

## Moteur et tests

| Dette | Référence | Priorité | Cible |
| --- | --- | --- | --- |
| `CombatRules`, `EffectRules` et `TriggerRules` forment le dernier groupe de modules qui s'appellent en boucle : la destruction (`CombatRules.destroy_piece`) termine les effets de la pièce (`EffectRules.end_effects_on_piece`) et déclenche ses effets (`TriggerRules.trigger`), dont la résolution passe par `EffectRules.resolve_effect`, qui peut détruire. Remède ouvert, à trancher par une décision. | 206.3.2, 206.3.2a, 207.4.7a | basse | J4 |
| Si `max_recycles_per_turn` devient borné, le paiement préparé pendant le tour adverse l'ignore (203.4.2 PROVISOIRE : illimité aujourd'hui). | 203.4.2 | moyenne | si 203.4.2 est borné |
| Une carte qui porte « une fois par tour » et plusieurs effets déclenchés est refusée par le catalogue. | 207.3.5, 207.3.7 | moyenne | J4 (`50-cartes/`) |
| `ActiveEffect.effect_kind` est une `StringName` alors que l'enum `EffectKind` existe. | 0010 | basse | J2 |
| Le test de 209.2.3 part d'un Hero déjà à 0 PV au lieu de l'y amener. | 209.2.3 | basse | J2 |
| Rien ne garantit que la suite tire la décision `OrderTriggers` (ordre des déclencheurs). | 0017 | basse | J2 |
| `RandomLegalAgent` épuise ses Sources en quelques centaines de pas ; sans pendule, des duels aléatoires ne finissent jamais. | 0019 | moyenne | J4 |
| `RandomLegalAgent` ne remplit jamais sa réserve d'Essence (il paie à l'annonce) : la réserve n'est couverte que par ses tests dédiés. | 203.6.5, 0026 | moyenne | J4 |
| Les conventions de l'étape 1.3 (zones, Essence, tour) ne sont écrites que dans le code. | `rules/CLAUDE.md` | basse | J2 |
| `DuelConfig.tie_destroys_both` ne connaît que l'option A de la décision de design 0053 ; `find_errors()` refuse l'option B, premier correctif nommé par 0053. | 206.3.6, 0053 | moyenne | avant J3 |

## Hôte et vue

| Dette | Référence | Priorité | Cible |
| --- | --- | --- | --- |
| Un agent qui ne propose aucune intention légale laisse `DuelHost` en `AWAITING_AI` avec une erreur à chaque image, jusqu'à la fin de sa pendule. | 0020 | moyenne | J4 |
| `EventText.describe` et sa table `SENTENCES` n'ont plus d'appelant dans le jeu depuis le retrait de `LogView` (décision 0041) : seuls `test_view_texts` et `test_event_player` les lisent. À reprendre par le relevé de playtest, ou à retirer. | 0041, 0027 | basse | 2.5 |
| `DuelSelection` ne gère qu'une cible par annonce ; les questions Q-098 et Q-099 du ruleset sont à trancher avant. | 207.5, 0024 | moyenne | première carte à plusieurs cibles |
| `SelectionCandidates` choisit entre `AttachGear` et `CastSpell` d'après le type de carte, et `DuelSelection` décide qu'une Source entre dans le paiement préparé par « compte > 0 » : deux restes de règle dans la vue, à remplacer par des requêtes du moteur. | 202.2, 203.2.1, 203.2.2, 0040 | basse | J3 |
| `PieceView` n'affiche que les mots-clés imprimés, aucun pour un jeton ; un mot-clé donné par un Gear, un Spell ou une aura demandera une requête de `DuelEngine`, comme pour la Force. | 202.4.13a | basse | J4 |
| Pendant un relais, le grand bouton du joueur précédent reste visible, inactif, derrière le rideau. | 0036 | basse | J3 |
