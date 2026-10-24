# 0045 — Temps de tour et temps de réponse à la place de la pendule

- Statut : acceptée ; modifiée par 0053
- Date : 2026-10-22
- Décideur : créateur du projet
- Périmètre : temps de jeu (ruleset 0.40, décision de design 0205 ; 209.4, 208.6, 209.2.10) ; `rules/` `DuelEngine`, `DuelConfig`, `app/` `DuelHost`, `ui/` `ClockView`, fiches de playtest

## Contexte

La pendule d'échecs (10 min par joueur pour la partie, sans ajout, défaite au temps ; 209.4, décision 0018) pénalise les gros tours de fin de partie, rend l'attente imprévisible et fait perdre sur un seul moment lent. Le duel à distance (0043) rend le joueur absent bloquant jusqu'à 10 min. 0018 prévoyait son réexamen « si le jeu passe en réseau ». Contraintes : moteur sans heure et déterministe (0001), temps injecté par l'hôte (0018, 0021), journal et replay (0022), aucun thread Web.

## Options envisagées

- Option A : garder la pendule et ajouter quelques secondes par tour. Peu de travail ; la défaite au temps et le blocage par un absent restent.
- Option B : hybride, temps de tour en pause pendant la pile, secondes rendues par action, temps de réponse, réserve, avertissements avant défaite, passe automatique avec réglage. Rythme prévisible et gros tours protégés ; le plus coûteux, plusieurs valeurs à régler.
- Option C : temps de tour et de réponse fixes (modèle Hearthstone). Simple ; gros tours coupés net.

## Décision

Option B, simplifiée à la demande du créateur pour être claire, concrète et anticipable, validée le 2026-10-22 :

- Temps de tour de 90 s, en pause dès que la pile n'est pas vide, repris là où il en était, remis à 90 s à chaque tour.
- 30 s neuves pour chaque décision prise pile non vide (chaque ajout à la pile ouvre une nouvelle fenêtre) ou hors du temps de tour.
- Expiration du tour = fin du tour ; expiration d'une réponse = passe. Le temps ne fait jamais perdre.
- Défaite après trois tours consécutifs terminés par expiration sans action.
- La fenêtre de réponse s'ouvre toujours, même si le joueur ne peut rien jouer : il passe lui-même ou à l'expiration de ses 30 s. La passe automatique quand aucune réponse n'est possible a été écartée par le créateur, pour garder une fenêtre toujours ouverte qui ne révèle rien.
- Ni réserve, ni secondes par action, ni avertissements, ni réglage.

Valeurs PROVISOIRES, à mesurer en playtest.

## Conséquences et vérification

- Mécanisme de 0018 conservé : l'hôte mesure le temps et appelle `advance_clock(elapsed_msec)` ; le moteur décompte sans lire l'heure, hors de tout `submit()`.
- L'état porte, par joueur, le temps de tour restant et le temps de réponse restant de la décision en cours (ils remplacent `clock_remaining_msec`). `DuelConfig` : `turn_time_msec` 90 000, `response_time_msec` 30 000, nombre de tours inactifs 3 ; `clock_duration_msec` et `clock_bonus_msec` retirés.
- À l'expiration, `advance_clock` applique la conséquence (fin du tour, passe, défaite par inactivité) et rend ses événements : ils sont journalisés par le temps déjà consigné (0022) et rejouables. `TimeExpired` change de sens ou est remplacé.
- `DuelHost` : la fenêtre de réponse retrouve une échéance de 30 s et une passe à expiration (0029) ; aucune passe automatique (208.6).
- Vue : `ClockView` affiche le temps qui tourne (tour ou réponse) ; plus de pendule globale.
- Fiches de playtest (0042) : temps des fenêtres et nouvelles mesures (tours et réponses expirés, défaites par inactivité).
- Expiration pendant un choix de cibles ou d'ordre des déclencheurs : tranchée par la décision de design 0206 (209.4.11, 209.4.11a, 209.4.12). Points laissés ouverts par le ruleset (Q-108 mulligan sans temps, Q-109 réponses hors de son tour et inactivité, Q-110 autres déclencheurs du lot) : rien ne s'implémente avant qu'il les tranche.
- Vérification : suite verte aux identifiants 209.4 et 208.6 ; un duel montre le temps de tour en pause pendant la pile et la passe à 30 s (étape 2.7 de la roadmap, avant le duel à distance).
- À réexaminer après le premier playtest (J3), selon les mesures.

## Références

Ruleset 0.40 (décision de design 0205), 209.4, 208.6, 209.2.10 ; décisions 0001, 0018 (modifiée), 0021, 0022, 0029 et 0042 (modifiées), 0043.
