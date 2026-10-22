# 0029 — Fenêtre de réponse dans l'hôte

- Statut : acceptée ; modifiée par le ruleset 0.38 (décision de design 0199) le 2026-10-21 : plus de décompte ni de passe automatique, `DuelHost` ouvre la fenêtre quand il attend un humain qui peut répondre ou passer et la ferme à l'affichage des événements de son geste ; `DuelConfig.response_window_msec` retiré, 208.6.2 PROVISOIRE n'ayant plus de valeur chiffrée (exception à « une valeur par règle PROVISOIRE ») ; les tests 208.6.3, 208.6.5 et 208.6.5a sont remplacés par des tests 208.6.2 et 208.6.4.
- Date : 2026-10-18
- Décideur : créateur du projet
- Périmètre : fenêtre de réponse à l'écran (`app/` DuelHost, `ui/` DuelSelection et écran de duel ; étape 2.3)

## Contexte

Ruleset 0.36, 208.6 (décision de design 0198) : sur écran, le jeu montre une fenêtre de réponse à un joueur chaque fois qu'il peut répondre ou passer (208.6.1, 208.6.7). Elle dure 2 s, valeur PROVISOIRE (208.6.2). Sans geste, il passe automatiquement (208.6.3) ; il peut passer avant (208.6.4). Le décompte s'arrête quand il commence une réponse (208.6.5) et il doit alors répondre ou passer lui-même (208.6.5a). Même fenêtre qu'il ait ou non une Réaction jouable (208.6.6). Sa pendule tourne pendant la fenêtre (209.4.4g). Le moteur sait déjà quand un joueur peut répondre ou passer ; reste à savoir qui décompte les 2 s. La roadmap (étape 2.3) demandait cette décision.

## Options envisagées

- A, dans l'hôte (`DuelHost`) : l'hôte décompte avec l'horloge monotone injectée (0021), la même que la pendule, et soumet lui-même `PassPriority` à l'expiration, inscrite au journal comme toute intention acceptée (0022) ; le replay reste exact. La vue affiche le temps restant lu auprès de l'hôte et le prévient d'une réponse commencée. Testable sans scène avec l'horloge manuelle. Coût : un peu de logique en plus dans l'hôte et une méthode publique pour signaler la réponse commencée.
- B, dans la vue (minuteur Godot) : le plus simple. Mais le passage automatique est une règle et vivrait dans `ui/` (interdit, CLAUDE.md §3), le minuteur s'arrête quand l'onglet du navigateur est caché alors que la pendule tourne, et rien n'est testable sans scène.
- C, dans le moteur (`rules/`) : la règle vit avec les autres et le moteur décompte comme la pendule. Mais « commencer une réponse » est un geste d'écran qui demanderait une nouvelle intention journalisée, la fenêtre ne vaut que sur écran (il faudrait un réglage pour la couper dans les tests et pour l'IA), et les 698 tests et duels aléatoires risquent d'être touchés.

## Décision

Option A, recommandée et choisie par le créateur le 2026-10-18.

- Durée : valeur de `DuelConfig` (`response_window_msec`, 2000), comme toute règle PROVISOIRE ; l'hôte la lit.
- Ouverture : quand l'hôte attend un humain qui peut répondre ou passer (pile non vide, intention de passe possible). Entre deux humains sur un même écran, seulement une fois le relais confirmé (le joueur a l'appareil). La pendule tourne comme avant (209.4.4f, 209.4.4g). Pas de fenêtre pour un agent (il joue sans délai) ni pendant une décision en attente (ordre des déclencheurs, cibles), qui n'est pas une réponse (208.6.7).
- Geste qui arrête le décompte (interprétation de « commencer une réponse » pour l'écran, le ruleset ne fixant pas le geste ; une réponse n'annonce que des Spells de vitesse Réaction, 208.2.3) : choisir une carte Réaction de sa main, ou cliquer l'une de ses Sources (préparation du paiement). Le décompte ne repart pas si le joueur annule : il doit répondre ou passer lui-même (208.6.5a).
- Vue : aucune règle. `DuelSelection` signale la réponse commencée, l'écran la transmet à l'hôte et affiche le temps restant (colonne de duel, sous « Passer », 0028).

## Conséquences et vérification

- Tests de l'hôte sans scène, horloge manuelle, nommés par identifiant : 208.6.1, 208.6.3 (passe inscrite au journal), 208.6.4, 208.6.5 et 208.6.5a, 208.6.6, 208.6.7, 209.4.4g. Les entrées 208.6.x et 209.4.4g de `RULES_WITHOUT_OWN_TEST` (`tests/test_rules_coverage.gd`) disparaissent au profit de ces tests.
- Test de `DuelSelection` : choisir une carte Réaction ou cliquer une Source en tour adverse signale une réponse commencée.
- Le replay rejoue les passes automatiques comme des intentions ordinaires.
- À réexaminer : si le playtest change la durée (208.6.2) ou la définition de la réponse commencée, si le ruleset précise le geste, ou si un mode réseau arrive (l'hôte serait alors côté serveur).

## Références

Ruleset 208.2.3, 208.2.4, 208.3.1a, 208.6, 209.4.4f, 209.4.4g, décision de design 0198 ; décisions 0003, 0020, 0021, 0022, 0024, 0028 ; `app/duel_host.gd` ; roadmap étape 2.3.
