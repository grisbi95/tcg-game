# 0057 — Choix pendant une résolution et sujet d'un effet sans cible

- Statut : acceptée
- Date : 2026-10-26
- Décideur : créateur du projet, en conversation
- Périmètre : `DuelEngine._resolve_stack`, `PendingDecision` et `EffectDefinition` pour les effets de cartes et de main ; étape c.4 du jalon J2c

## Contexte

Ruleset 0.53 : chapitres 212 (Défausser : carte choisie à la résolution, 212.1.3, qui n'est pas une cible, 212.1.4) et 217 (Regarder le dessus du deck : laisser la carte ou la mettre dessous, 217.1.2, 217.1.3), 209.4.7c et 209.4.7d (temps de réponse pendant ces choix), 209.4.13 et 209.4.14 (tirage au sort à l'expiration, décision de design 0242 du ruleset). Le catalogue de `docs/ruleset/50-cartes/` demande : Étude et Grimoire « piochez…, puis défaussez une carte de votre main », Observatoire « regardez la carte du dessus de votre deck ; vous pouvez la mettre sous votre deck », Lettré, Bibliothèque, Inspiration, Pilleuse « piochez », Charge et Chef de guerre « réveillez une Unit ciblée », Éclaireur et Furieux « réveillez cette Unit ». Le code : toute la pile se résout d'un bloc en une soumission (`_resolve_stack`, 208.3.2) ; aucun choix n'interrompt une résolution (les effets déclenchés attendent la fin du bloc, 0017) ; `EffectDefinition.find_errors()` exige une cible pour tout effet à la pile. Contraintes : aléa par `state.rng` seulement ; une attente est une `PendingDecision` (0009) avec temps de réponse ; le journal enregistre les intentions ; victoire vérifiée après chaque entrée.

## Options envisagées

Question 1, suspendre une résolution pour un choix.

- Option A : reprise au milieu d'une entrée. `DuelState` retient l'entrée en cours et le rang de son prochain effet ; l'effet qui demande un choix pose une `PendingDecision` (`CHOOSE_DISCARD`, `CHOOSE_TOP_CARD_PLACE`) et la résolution s'arrête ; la réponse (`ChooseDiscard`, `ChooseTopCardPlace`) applique le choix, termine les effets restants de l'entrée, puis reprend le bloc. Bénéfice : générale, tout choix futur passe par le même chemin, où qu'il soit sur la carte. Coût : deux champs d'état (avec `clone()`) et une boucle de résolution qui reprend.
- Option B : le choix en dernier effet de sa carte. `find_errors()` l'exige ; l'entrée finit de se résoudre au choix, seul le bloc reprend. Bénéfice : pas de rang d'effet à retenir ; les trois cartes du catalogue s'y plient. Coût : contrainte de forme sur les cartes, à lever dès qu'une carte mettra un choix avant un autre effet.

Question 2, ce que touche un effet sans cible.

- Option A : champ explicite `subject` sur `EffectDefinition` : cibles (défaut quand l'effet a une cible), joueur à qui appartient l'effet (« piochez », « défaussez », « regardez votre deck »), ou pièce source (« réveillez cette Unit ») ; `find_errors()` vérifie l'accord entre `subject` et `kind`. Bénéfice : le JSON dit ce qu'il touche, dans l'esprit de 0010.
- Option B : déduit du `kind`. Piocher, défausser, regarder touchent le joueur ; réveiller touche sa cible ou, sans cible, la pièce source. Bénéfice : pas de champ. Coût : règle cachée dans le moteur ; « votre adversaire pioche » demanderait un autre `kind`.

## Décision

Question 1 : option A. Question 2 : option A. B écartée dans les deux cas. Choix du créateur, 2026-10-26.

## Conséquences et vérification

- Complète 0009 (deux genres d'attente posés pendant une résolution) et 0010 (clé `subject` ; effet à la pile sans cible admis selon `subject`). Complète 0017 sur un point : un choix peut interrompre le bloc de résolution ; les effets déclenchés attendent toujours la fin du bloc.
- Travail induit à c.4 : quatre `kind` (piocher, défausser, regarder le dessus du deck, réveiller) ; événement de défausse distinct de `CardDiscarded` (212.2.1 à 212.2.2d) ; expiration par tirage au sort (209.4.13, 209.4.14) par `state.rng` ; codec du journal et `RandomLegalAgent` pour les deux intentions nouvelles.
- Hors c.4 : affichage du choix et de la carte regardée (c.7 ; 217.1.5 se garantit dans la vue, le moteur est omniscient, 0043) ; déclencheurs « début du tour » et « défausse », et 212.2.5 (c.5).
- Vérification : suites vertes, chaque règle citée par un test nommé par identifiant.
- Réexamen : si un choix doit naître pendant la résolution d'un combat ou d'un effet déclenché d'un autre joueur, ou si un troisième genre de choix à la résolution apparaît.

## Références

- Décisions 0009, 0010, 0017, 0043.
- `docs/ruleset/` édition 0.53, chapitres 212, 217, 209.4.7c, 209.4.7d, 209.4.13, 209.4.14.
- `docs/roadmap.md` (étape c.4), branche `feat/c.4-effets-de-main`.
