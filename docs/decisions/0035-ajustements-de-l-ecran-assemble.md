# 0035 — Ajustements de l'écran assemblé

- Statut : acceptée
- Date : 2026-10-20
- Décideur : créateur du projet
- Périmètre : écran de duel (`ui/duel_screen.tscn`, étape 2.3)

## Contexte

L'écran assemblé selon 0030 et 0032 a été capturé en 1920×1080 et en 1280×720 ; deux constats. Les repères A–E sous le plateau mordent de 5 px sur le haut de la main (y 844) ; la maquette avait le même défaut. En 1280×720, le texte des cartes de la main descend vers 8 px et se lit mal, alors que noms, chiffres, pièces et pendules restent lisibles. Cette décision modifie 0030 (cote y du plateau et de la colonne de duel).

## Options envisagées

- Repères A–E : remonter le plateau et la colonne de duel de 6 px, à y 88 (la colonne garde la hauteur du plateau, 731 px, alignée sur lui) : retenu, recommandé. Contre : placer les repères au-dessus du plateau, contraire à l'usage (A–E du côté du joueur A).
- Texte des cartes de main en 1280×720 : garder les tailles, l'aperçu au survol servant à lire le texte (rôle donné par 0030), et mesurer la lisibilité au playtest J3 : retenu, recommandé. Contre : agrandir le texte des cartes de main, ce qui tronque davantage, le format 158×220 étant fixe.

## Décision

Choix du créateur le 2026-10-20. Plateau et colonne de duel à y 88 (au lieu de 94 en 0030). Tailles de texte inchangées en 1280×720 ; lisibilité mesurée au playtest J3.

## Conséquences et vérification

- Les repères A–E ne touchent plus la main ; le texte des cartes de main reste petit en 1280×720 et se lit à l'aperçu.
- Vérification : capture de l'écran au mulligan, lettres A–E sans chevauchement.
- À réexaminer si le playtest J3 montre que le texte des cartes de main gêne malgré l'aperçu.

## Références

Décisions 0028, 0030, 0032 ; maquettes `docs/maquettes/ecran-de-partie-v1.html` et `-v2.html` ; roadmap étapes 2.3 et J3.
