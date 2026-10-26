# Backlog des dettes techniques

> **Rôle** : seul propriétaire des dettes techniques (décision 0038) : une ligne par dette, sa référence (règle ou décision), sa priorité et sa cible. Une dette réglée se supprime. Les questions de règles vont dans [ruleset/02-questions-ouvertes.md](ruleset/02-questions-ouvertes.md), les mesures de playtest dans [ruleset/70-playtest/protocole.md](ruleset/70-playtest/protocole.md), le plan dans [roadmap.md](roadmap.md).

Priorité : **haute** = écart au ruleset ou défaut visible en partie ; **moyenne** = manque qui bloquera une étape nommée ; **basse** = propreté.

## Moteur et tests

| Dette | Référence | Priorité | Cible |
| --- | --- | --- | --- |
| `CombatRules`, `EffectRules` et `TriggerRules` forment le dernier groupe de modules qui s'appellent en boucle : la destruction (`CombatRules.destroy_piece`) termine les effets de la pièce (`EffectRules.end_effects_on_piece`) et déclenche ses effets (`TriggerRules.trigger`), dont la résolution passe par `EffectRules.resolve_effect`, qui peut détruire. Remède ouvert, à trancher par une décision. | 206.3.2, 206.3.2a, 207.4.7a | basse | J4 |
| Ruleset 0.45 sans code : l'Ordre du Hero et les effets déclenchés portés par le Hero (décision de design 0211, chapitre 211, 202.3.19 à 202.3.21, 208.1.12) ne sont pas implémentés ; il faut une décision de code qui modifie 0047 (intention, entrée de la pile, `HeroDefinition`), l'annonce d'un Ordre comptée pour l'inactivité (209.2.10), la réponse par un Ordre de vitesse Réaction (208.2.3), la création de jeton par un Ordre (202.4.6, 201.5.4c) et le chemin de sélection de la vue. | 0211, 0047 | moyenne | avant les Heroes du catalogue |
| Ruleset 0.46 sans code : passif du Hero facultatif (202.3.11 ; `HeroDefinition` exige encore un passif, testé par `test_catalog.gd`), texte du Hero public (201.4.12), Défausser (chapitre 212), coût X (213.1) et valeur X fixée à la résolution (213.2). | 0212 à 0216 | moyenne | avant les cartes du catalogue |
| Ruleset 0.47 sans code : Échanger (chapitre 214, tout ou rien, 200.4.2a et 207.5.4a), au moins une capacité par Hero (202.3.22), tirage au sort de la défausse à l'expiration du temps de réponse (209.4.13), X choisi avant les cibles (213.1.9 à 213.1.11), Force lue pour X sans Assaut ni Rempart (213.2.4). | 0217 à 0222 | moyenne | avant les cartes du catalogue |
| Si `max_recycles_per_turn` devient borné, le paiement préparé pendant le tour adverse l'ignore (203.4.2 PROVISOIRE : illimité aujourd'hui). | 203.4.2 | moyenne | si 203.4.2 est borné |
| Une carte qui porte « une fois par tour » et plusieurs effets déclenchés est refusée par le catalogue. | 207.3.5, 207.3.7 | moyenne | J4 (`50-cartes/`) |
| `ActiveEffect.effect_kind` est une `StringName` alors que l'enum `EffectKind` existe. | 0010 | basse | J4 |
| Le test de 209.2.3 part d'un Hero déjà à 0 PV au lieu de l'y amener. | 209.2.3 | basse | J4 |
| Rien ne garantit que la suite tire la décision `OrderTriggers` (ordre des déclencheurs). | 0017 | basse | J4 |
| `RandomLegalAgent` épuise ses Sources en quelques centaines de pas ; depuis la fin de la défaite au temps (0045), rien ne borne plus un duel aléatoire où les deux agents agissent : `test_random_duels.gd` à revoir à l'étape 2.7. | 0019, 0045 | moyenne | J4 |
| Depuis la pioche de 1 carte par tour (0.43), deux `RandomLegalAgent` peuvent garder la main pleine sans vider leur deck : la pioche est bloquée par la limite de main, la fatigue n'arrive pas et le duel ne finit pas. `test_duel_host.gd` (0020) passe par une graine choisie à l'essai (2 ; la 3 ne finit pas en 5000 pas) : critère de fin à revoir. | 204.3.6, 201.3.4, 0020 | moyenne | J4 |
| `RandomLegalAgent` ne remplit jamais sa réserve d'Essence (il paie à l'annonce) : la réserve n'est couverte que par ses tests dédiés. | 203.6.5, 0026 | moyenne | J4 |
| Les conventions de l'étape 1.3 (zones, Essence, tour) ne sont écrites que dans le code. | `rules/CLAUDE.md` | basse | J4 |
| `DuelConfig.tie_destroys_both` ne connaît que l'option A de la décision de design 0053 ; `find_errors()` refuse l'option B, premier correctif nommé par 0053. | 206.3.6, 0053 | moyenne | avant J3 |
| La fixture de rejeu (`tests/fixtures/replay_random_duel`) a été régénérée trois fois pendant J2 (ruleset 0.39, 0.41, 0.43) : à chaque changement de règle l'empreinte repart de zéro et ne détecte plus une régression du moteur. Remède : conserver en fixture le journal d'une vraie partie de playtest (J3), rejoué comme la fixture aléatoire, et noter dans le rapport de `/sync-rule` l'écart attendu avant de régénérer. | 0022, 0047, retro J2 | basse | J3 |

## Hôte et vue

| Dette | Référence | Priorité | Cible |
| --- | --- | --- | --- |
| Un agent qui ne propose aucune intention légale laisse `DuelHost` en `AWAITING_AI` avec une erreur à chaque image ; depuis 0045 seule la défaite par inactivité (209.2.10) y met fin. | 0020, 0045 | moyenne | J4 |
| `DuelJournal` garde le temps des fenêtres de réponse et les réponses commencées (décision 0042), que la fiche ne relève plus depuis le ruleset 0.40 (le protocole les a retirées) : à retirer du journal et de l'hôte avec leurs tests, ou à rendre au protocole. | 0042, 0045, 0205 | basse | J3 |
| Pendant un choix de cibles d'un effet déclenché qui ne peut être abandonné (autres effets du lot, « une fois par tour »), l'expiration ne fait rien : le temps reste à 00:00 et rien ne le signale au joueur, jusqu'à ce que Q-110 du ruleset soit tranchée. | 209.4.11a, 0045, Q-110 | moyenne | avant J3 |
| `EventText.describe` et sa table `SENTENCES` n'ont plus d'appelant dans le jeu depuis le retrait de `LogView` (décision 0041) : seuls `test_view_texts` et `test_event_player` les lisent. Le relevé de playtest (2.5) ne les lit pas : à retirer avec leurs tests. | 0041, 0027 | basse | J3 |
| Dans la pile, un combat en attente d'action normale, sans carte, prend la teinte d'un Spell (`DuelViewModel._stack_tint`) ; une teinte de l'attaquant ou une teinte propre serait plus juste. | 205.6, 0046 | basse | J3 |
| `DuelSelection` ne gère qu'une cible par annonce ; les questions Q-098 et Q-099 du ruleset sont à trancher avant. | 207.5, 0024 | moyenne | première carte à plusieurs cibles |
| `SelectionCandidates` choisit entre `AttachGear` et `CastSpell` d'après le type de carte, et `DuelSelection` décide qu'une Source entre dans le paiement préparé par « compte > 0 » : deux restes de règle dans la vue, à remplacer par des requêtes du moteur. | 202.2, 203.2.1, 203.2.2, 0040 | basse | J3 |
| `PieceView` n'affiche que les mots-clés imprimés, aucun pour un jeton ; un mot-clé donné par un Gear, un Spell ou une aura demandera une requête de `DuelEngine`, comme pour la Force. | 202.4.13a | basse | J4 |
| Le relevé de playtest (`PlaytestRecorder`, `PlaytestSheet`) n'a pas la colonne « PV perdus » de chaque Hero par tour, ajoutée à la fiche par la décision de design 0202 (ruleset 0.39). | 0202, protocole | moyenne | avant J3 |
| Le thème garde les variations `CountdownBar` et `CountdownLabel` de l'ancien décompte de la fenêtre de réponse (retiré en ruleset 0.38), contrôlées par `test_duel_theme.gd` ; à retirer par l'éditeur avec leurs tests. | 0199 (ruleset), 0029 | basse | J3 |
| Duel à distance : une intention du second écran en file chez l'hôte (`RemoteHostLink`) y reste si le tour ou la fenêtre de réponse passe à l'expiration entre-temps ; elle serait soumise la prochaine fois que B est attendu. Remède : l'intention porte l'état qu'a vu le second écran, l'hôte refuse une intention périmée. | 209.4.9, 209.4.10, 0049 | moyenne | avant J3 |
| Les tests du relais (`tools/relay/`, `npm test`) ne tournent pas dans la CI. | 0049 | basse | J3 |
| `RelayConnection` code les messages de contrôle du relais (`create`, `join`, `created`, `paired`, `peer_left`, `error`) en chaînes brutes ; un `enum` converti par `find_key`, comme `RemoteMessage.Kind`, serait plus sûr. | 0049, `code-guidelines.md` §6 | basse | J3 |
| L'enchaînement de connexion au relais (créer, rejoindre, appariement, attente de la préparation, erreurs, `LobbyStep`) vit dans `MainScreen` sans test ; à extraire dans un objet de `app/` testé avec `LoopbackConnection`. | 0050 | moyenne | avant J3 |
| Le retournement du plateau et des zones pour B (`BoardView._build`, `ScreenSides`) n'a pas de test ; l'ordre des cases pourrait se lire dans une fonction statique. | 0050 | basse | J3 |
| Après un déploiement, le navigateur garde jusqu'à 10 minutes l'ancien `index.pck` de GitHub Pages : un joueur peut charger une ancienne version (relais local, édition différente). Remède : nom ou paramètre de version sur les fichiers de l'export. | 0005, 0049 | moyenne | avant J3 |
