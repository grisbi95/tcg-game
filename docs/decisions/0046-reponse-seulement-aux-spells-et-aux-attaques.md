# 0046 — Réponse seulement aux Spells et aux attaques

- Statut : acceptée
- Date : 2026-10-22
- Décideur : créateur du projet
- Périmètre : annonces et fenêtre de réponse (ruleset 0.41, décision de design 0207 ; 208.2.4, 208.6) ; `rules/` `StackRules`, `ActionRules`, `TurnRules`, `TriggerRules`, `app/` `DuelHost`, `ui/` fenêtre de réponse

## Contexte

Chaque annonce (déploiement, action normale, Spell, Gear, pouvoir du Hero) passe par la pile et ouvre une fenêtre de réponse à l'adversaire (208.2.4, 208.6 ; décisions 0029, 0042, 0045). Un tour fait beaucoup d'allers-retours même quand rien ne se joue. Le créateur veut limiter les piles pour un jeu plus fluide et plus rapide. La règle est consignée en parallèle dans le ruleset.

## Options envisagées

- Option 1 : réponse seulement aux Spells (vitesse Action ou Réaction) et aux attaques (action normale sur une case occupée par un ennemi). Déploiement, déplacement vers une case libre, déplacement du Hero, Gear et pouvoir du Hero se résolvent aussitôt. Bénéfice : le moins de piles, règle simple. Coût : plus de piège par Réaction sur un déplacement ou un déploiement.
- Option 2 : comme l'option 1, mais le pouvoir du Hero et tous les effets déclenchés gardent leur fenêtre. Bénéfice : effets forts contrables. Coût : règle moins nette, piles plus fréquentes.
- Option 3 : fenêtre partout, sautée quand l'adversaire n'a aucune Réaction jouable. Bénéfice : règles presque inchangées. Coût : révèle la main (bluff perdu), contraire à 208.6.6.

## Décision

Option 1, recommandée et choisie par le créateur le 2026-10-22. Sous-choix : un effet déclenché suit l'annonce qui l'a créé. Déclenché par une annonce sans réponse, il se résout aussitôt, sans fenêtre ; déclenché par un Spell ou une attaque, il garde la possibilité de réponse.

## Conséquences et vérification

- Moteur : une annonce sans réponse se résout dans le même `submit`, avec ses effets déclenchés, sans donner la main à l'adversaire ni ouvrir de temps de réponse. Elle garde son passage par la pile et ses événements, pour que le flux d'événements et le journal restent uniformes. `validate()` reste pur.
- Hôte et vue : la fenêtre de réponse (0029) et ses mesures (0042) ne s'ouvrent plus que pour un Spell ou une attaque ; le temps de tour (0045) n'est en pause que pendant une pile qui attend une réponse.
- Les décisions 0029, 0042 et 0045 restent en vigueur : leur mécanisme ne change pas, seule la fréquence des fenêtres baisse. 0029 est modifiée (le moment où l'hôte ouvre la fenêtre).
- Travail induit : `rules/stack_rules.gd`, `stack_entry.gd`, `action_rules.gd`, `zone_rules.gd`, `combat_rules.gd`, `duel_state.gd`, `rules/CLAUDE.md`, `intents/pass_priority.gd`, `events/card_returned_to_hand.gd`, `events/piece_entered_attacking.gd` ; tests `test_208_6_response_window.gd`, `test_rules_coverage.gd`, `test_duel_selection.gd`, `test_duel_center_presenter.gd`, `support/response_window_samples.gd`, `playtest_scenarios.gd`, `human_duel_driver.gd`, `duel_checks.gd`.
- Vérification : suite verte aux identifiants 208.2.4 et 208.6 ; un duel montre un déploiement et un déplacement libre résolus sans fenêtre, un Spell et une attaque avec fenêtre.
- À réexaminer si le playtest J3 montre que les déplacements et déploiements sont devenus impossibles à contrer et que le jeu y perd en profondeur, ou si les piles restent longues malgré la règle.

## Références

Ruleset 0.41 (décision de design 0207), 208.2.4, 208.6, 208.6.6 ; décisions 0029 (modifiée), 0042, 0045 ; roadmap étape 2.7.
