# 0021 — Horloge réelle monotone, injectée

- Statut : acceptée
- Date : 2026-10-17
- Décideur : créateur du projet
- Périmètre : source de temps de l'hôte (`app/`, étape 2.1 ; ruleset 209.4.4f)

## Contexte

Le moteur ne lit jamais l'heure ; l'hôte lui donne le temps écoulé par `advance_clock(elapsed_msec)` (0018). Sur le Web, la pendule doit être indépendante des images rendues. Décision de design 0187 du ruleset (règle 209.4.4f, édition 0.34) : la pendule du joueur attendu tourne aussi pendant le relais et pendant l'affichage des effets.

## Options envisagées

- Option A : compteur monotone de Godot (`Time.get_ticks_msec()`) lu par une petite classe `MonotonicClock` (`app/`, `now_msec()`), remplacée dans les tests par une horloge manuelle (`ManualClock`, `tests/support/`). Indépendant des images ; coût : une classe de plus.
- Option B : somme des `delta` de `_process`. Plus simple ; mais dépend du rendu : onglet caché, le temps s'arrête et un joueur pourrait geler sa pendule.

## Décision

Option A, recommandée et choisie par le créateur le 17 octobre 2026.

## Conséquences et vérification

- À chaque `tick()`, l'hôte calcule l'écart depuis la lecture absolue précédente et appelle `advance_clock(écart)` si l'écart est positif. Aucun arrondi ne s'accumule.
- Onglet du navigateur caché : le temps est rattrapé au retour, l'instant d'épuisement restant exact (0018).
- Aucun temps avant le démarrage ni après la fin du duel.
- Aucun temps n'est décompté pendant le mulligan (209.4.2d). La pendule tourne en RELAY, PLAYING_EVENTS et AWAITING_AI dès qu'une pendule tourne selon le moteur (209.4.4f, décision de design 0187 du ruleset).
- `rules/` ne lit toujours jamais l'heure.
- Vérification : tests de l'hôte avec `ManualClock` (écart positif, nul, rattrapage, rien avant ni après le duel, pendule qui tourne en relais).
- À réexaminer si le Web impose une autre source de temps ou si le jeu passe en réseau.

## Références

Ruleset 209.4.4f et décision de design 0187 ; décisions 0001, 0018, 0020.
