# 0031 — Annonce sans confirmation

- Statut : acceptée
- Date : 2026-10-18
- Décideur : créateur du projet
- Périmètre : `DuelSelection` (`ui/`, étape 2.3)

## Contexte

La décision 0024 prévoyait un état CONFIRM : un Spell, un Gear ou le pouvoir du Hero, une fois sa cible choisie (ou aussitôt sans cible), attendait un clic sur « Confirmer » avant d'être annoncé et payé. En préparant la colonne de duel (0030), la place de « Confirmer » s'est posée.

## Options envisagées

- Garder la confirmation : filet contre un clic de travers ; un clic de plus à chaque annonce.
- Annoncer dès que l'annonce est complète (retenu) : un clic de moins ; une erreur de cible est la responsabilité du joueur.

## Décision

Choix du créateur, le 2026-10-18 (« dommage que le joueur se trompe, mais c'est sa faute »). Une annonce part dès qu'elle est complète : aussitôt pour une carte ou un pouvoir sans cible, au clic sur la cible sinon. L'état CONFIRM de `DuelSelection` disparaît ; restent IDLE, CARD_CHOSEN, PIECE_CHOSEN, TARGET_PENDING. « Confirmer » ne sert plus qu'au mulligan (cartes à écarter). L'ordre des effets déclenchés part déjà au dernier clic. Annuler une sélection en cours reste possible (re-cliquer la carte choisie, ou « Annuler »).

## Conséquences et vérification

- Un clic de moins par annonce ; aucune reprise possible après le clic de cible.
- Tests de `DuelSelection` (`tests/test_duel_selection.gd`) : Spell ciblé annoncé au clic sur la cible ; Spell sans cible annoncé au clic sur la carte ; `can_confirm` vrai seulement au mulligan.
- Reste à décider (0030, points ouverts) : la place de « Confirmer » (mulligan), « Annuler » et « Pouvoir du Hero ».
- À réexaminer si le playtest J3 montre des annonces involontaires fréquentes.

## Références

Décisions 0024 (modifiée : état CONFIRM retiré), 0029, 0030 ; `ui/CLAUDE.md` ; `ui/duel_selection.gd` ; roadmap étape 2.3.
