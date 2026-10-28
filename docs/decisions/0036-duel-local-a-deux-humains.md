# 0036 — Duel local à deux humains : relais, préparation, fin de partie et scène racine

- Statut : acceptée ; point 1 modifié par 0043 ; point 2 modifié par 0048 ; point 6 modifié par 0075
- Date : 2026-10-20
- Décideur : créateur du projet
- Périmètre : relais, préparation, fin de partie, abandon et scène principale (`ui/`, `app/`, étape 2.4)

## Contexte

L'écran de duel (2.3) relaie automatiquement entre deux humains, ce qui montre la main de l'autre au changement. Il démarre par `ProvisionalDuelLaunch` (faux deck, graine tirée) et annonce la fin en une ligne. `DuelHost` (0020) a déjà l'état RELAY, `confirm_relay()` et `concede(side)` (209.2.5). La pendule tourne pendant le relais (209.4.4f) ; la fenêtre de réponse s'ouvre après lui (0029). L'appareil change de main chaque fois que l'autre peut répondre : deux relais par carte annoncée, sans raccourci (208.6.6). Cette décision complète 0032 (point 8).

## Options envisagées

Retenue d'abord, puis l'autre.

1. Cadre du playtest J3 : même appareil d'abord, un navigateur, deux joueurs côte à côte (playtest rapide, moteur et hôte réutilisés par un futur réseau ; relais fréquents) ; ou chacun sur son navigateur (plus proche du jeu final, mais jalon Réseau avant J3 : serveur, hôte côté serveur pour cacher les mains, GitHub Pages insuffisant (0005), fenêtre de 2 s à revoir (0029), déconnexions).
2. Écran de relais : rideau sur la main du bas seulement, « Joueur B, à vous » et « Voir ma main » (léger, le reste est public, 201.4) ; ou voile opaque sur l'écran entier (plus net, plateau invisible avant le clic, plus lourd à chaque relais).
3. Premier joueur : alterné comme le playtest, A à la partie 1 puis alternance à chaque « Rejouer » (décisions 0158 et 0168 du ruleset), imposé dans le `DuelSetup` (0012), écart noté avec 204.1.16 ; ou tiré au sort (204.1.14, fidèle, séries déséquilibrées) ; ou sélecteur Tirage / A / B (souple, un réglage de plus).
4. Fin de partie : panneau au centre sur le jeu figé et assombri (plateau final visible) ; ou écran à part (plus de place pour des statistiques, plateau perdu).
5. Abandon (209.2.5) : petit bouton « Abandonner » avec confirmation ; ou pas d'abandon (plus simple, mais aucune trace d'une partie abandonnée).
6. Enchaînement des écrans : scène racine `ui/main.tscn` qui remplace l'écran du moment ; ou `change_scene_to_file` par `AppEvents.scene_requested` (la préparation et l'alternance exigeraient un état global, interdit par 0006).

## Décision

Choix du créateur, le 2026-10-20, option recommandée partout.

1. **Même appareil d'abord.** Le réseau devient un jalon à part après J3, hors périmètre d'ici là.
2. **Rideau sur la main du bas** : « Joueur B, à vous » et « Voir ma main » ; plateau, pile, Sources et pendules restent visibles. Pendant le relais, commandes bloquées et aperçu de la main impossible. Il vaut aussi à l'appel du premier joueur et entre les mulligans de A et de B (204.2.3).
3. **Premier joueur alterné** (A à la partie 1, puis l'autre à chaque « Rejouer »). Écran de préparation : deck de test affiché pour A et B, graine tirée, affichée et modifiable, « Partie N · Joueur X commence », bouton « Commencer ». Mulligan dans la main (0032 point 5), A puis B avec relais.
4. **Panneau de fin au centre** : vainqueur et raison (PV à 0, pendule, abandon, nul), tour, durée ; boutons « Rejouer » (l'autre commence, nouvelle graine) et « Préparation ».
5. **Bouton « Abandonner »** discret près de la pendule du joueur qui a l'appareil, confirmation « Abandonner la partie ? Oui / Non ». Il s'ajoute au grand bouton unique de 0032, qui reste seul pour jouer. La fiche de playtest (2.5) notera l'abandon.
6. **Scène racine `ui/main.tscn`** : préparation, duel, fin, puis rejouer ou préparation. Elle lance `DuelScreen.start_duel`, retient le numéro de partie et le prochain premier joueur ; appels directs et signals vers le parent, sans état global. Elle sera déclarée scène principale dans `project.godot` une fois vérifiée (autorisation du créateur).

## Conséquences et vérification

- `ProvisionalDuelLaunch` disparaît. Relais et fin vivent dans `OverlayLayer` de `DuelScreen` (0032 point 8). L'alternance et la graine sont tenues par une petite classe sans scène, dans `app/` ; aucune règle dans `ui/`.
- Vérification : tests sans scène de l'alternance et de la préparation ; scène lancée, duel complet à deux, captures du rideau, du panneau de fin et de la préparation.
- À réexaminer après J3 (lourdeur du relais, rythme), à l'arrivée du réseau ou d'un mode contre l'IA.

## Références

Ruleset 201.4, 204.1.14, 204.1.16, 204.2.2, 204.2.3, 208.6, 209.2.5, 209.4.4f, décisions 0158 et 0168 du ruleset, protocole de playtest ; décisions 0005, 0006, 0012, 0020, 0029, 0030, 0032 ; roadmap 2.4 à 2.6 et J3.
