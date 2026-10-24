# 0053 — Fiche technique de l'écran de duel, version 1

- Statut : acceptée
- Date : 2026-10-24
- Décideur : créateur du projet
- Périmètre : écran de duel, jalon J2b, étape 2b.2 ; prépare 2b.3 (gabarit en gris) et 2b.5 (habillage)

## Contexte

La décision 0052 a créé la fiche vivante `docs/fiches/ecran-de-duel.md` et la maquette annotée. Le créateur a validé la fiche en version 1 après avoir tranché les choix ci-dessous. Cette décision les consigne ; les cotes, les détails et les assets restent dans la fiche, qui fait référence.

## Options envisagées

1. Compteurs de Sources. A : un seul compteur, la réserve d'Essence (201.4.10) ; Sources inclinées, en réserve et en Fonte se lisent par l'état des emplacements (201.4.4, 201.4.5, 201.4.6). B : une bulle au survol, moins visible. C : supprimer l'information, ce qui contredirait 201.4.5 et 201.4.6.
2. Cartes Hero de la colonne de droite. A : les supprimer (elles servaient au pouvoir du Hero, retiré par 0047) ; l'aperçu de la pièce Hero montre sa carte. B : les garder, sans usage.
3. Affichage du temps (plus de pendule globale depuis 0045). A : une barre fine de 6 px par camp, qui se vide, au bord du plateau du côté du joueur qui doit agir. B : un anneau sur le bouton. C : une barre dans la colonne. Sous-choix Q8 : une seule barre, le reste d'un tour en pause écrit en petit ; ou deux barres empilées.
4. Colonne de duel. A : colonne rangée (en-tête, pile qui s'étend, grand bouton ancré). B : bouton rond sur le plateau, pile en mini-cartes : le plus gros changement, hauteur parfois insuffisante. C : pile en cascade, bouton au milieu : laisse du vide.
5. Place libérée à droite. A : la laisser vide. B : un historique des coups (reviendrait sur le point 8 de 0030). C : des plaques de joueurs (répéteraient les PV).
6. Aperçu et bulles (Q1). A : aperçu fixe à gauche, bulles empilées à sa droite. B : place réservée sous l'aperçu : 520 px disponibles pour 590 nécessaires, aperçu réduit à environ 269×374. C : aperçu qui suit la souris.
7. Mains (Q2). A : centrées sur la colonne du milieu. B : x 424 et main adverse centrée sur l'écran.
8. Écran plus haut que 16:9 (Q3). A : le plateau grandit en restant carré. B : taille fixe.
9. Pièce endormie (Q4, dette « avant J3 »). A : illustration grisée. B : pastille « Zz ». C : pièce estompée à 55 %, confondue avec une pièce désactivée. D : pièce inclinée, qui déborde de sa case.
10. Choix demandés par le moteur (Q5). A : sur le plateau et dans la pile. B : fenêtre au centre, qui cacherait le plateau.
11. Bouton désactivé (Q6). A : reste en place, grisé. B : caché.
12. Alerte sous 10 s. A : garder l'alerte orange de la barre, signal visuel seul, sans message ni effet de règle (le « ni avertissements » de 0045 vise les règles, pas l'affichage). B : aucune alerte.

## Décision

Choisi par le créateur le 2026-10-24 :

1. A. Un compteur, la réserve d'Essence (201.4.10), au comportement actuel (203.6, décision 0032) : la réserve pendant son tour, le paiement préparé pendant le tour adverse (203.6.2). Emplacements en 4 états : en jeu redressée, en jeu inclinée (201.4.4), en réserve en pointillé (201.4.5), en Fonte barrée (201.4.6). Leur nombre est `DuelConfig.total_sources_per_player` (203.5.7, PROVISOIRE).
2. A. `HeroCardView` est retiré en 2b.3. Modifie 0032 sur ce point.
3. A, barre de 6 px par camp : au-dessus pour l'adversaire, au-dessous pour soi, couleur du camp, secondes au bout. Deux états seulement : active (1) et inactive (piste vide à 0,25, sans secondes) ; pendant le mulligan, les deux sont inactives (209.4.2d). Q8 : une seule barre ; le reste d'un tour en pause s'écrit au bout de la barre de ce camp, en petit à 0,55 (« tour : 54 s »). Les cases passent de 143 à 139, la grille fait 711 en x 615, y 98 (`PlayRow` alignée à droite dans la colonne du milieu), la pièce 125, la colonne de duel 220×711 en x 1342, les barres ont la largeur de la grille et les lettres A–E passent sous la barre du bas (y 821) (modifie les cotes de 0030 et 0035). `ClockView` (0045) est remplacé par un composant de barre de temps.
4. A. En-tête (tour ou taille de la pile, qui doit agir, abandon en bouton à icône drapeau), pile qui s'étend (cadre en pointillé « Pile vide »), grand bouton ancré avec une ligne d'aide. Le décompte de réponse est retiré, car il est sur la barre.
5. A. Laissée vide ; un décor sera possible en 2b.4.
6. A. Aperçu fixe à gauche, 348×484, couche Informations ; bulles de 260 px à sa droite, par-dessus le bord gauche du plateau le temps du survol.
7. A. La main du bas est en x 425, centrée dans la colonne du milieu.
8. A.
9. A, à l'initiative du créateur : illustration en gris désaturé, le reste en couleur ; sans illustration, l'icône du type. Shader de niveaux de gris compatible GL Compatibility, sans asset en plus ; bulle « Endormie » au survol. Le gris s'applique toujours aux pièces du joueur de l'écran (en duel à deux sur un appareil, celui qui a l'appareil, 0030). Pour les pièces adverses, il suit la réponse à la question ouverte Q-104 du ruleset (l'état endormi est-il visible de l'adversaire ?), que la vue n'anticipe pas : tant que Q-104 est ouverte, rien de nouveau ne s'affiche sur une pièce adverse. Q-104 attendait de voir l'affichage sur écran : la maquette et cette décision servent à la trancher, entre deux étapes.
10. A. Cibles en jaune, en-tête « Choisis une cible », bouton « Confirmer », ordre des déclencheurs donné comme aujourd'hui, par pastilles 1, 2, 3 dans la pile. Seul le joueur qui choisit voit ses déclencheurs en attente (208.4.6, 201.4.7).
11. A. Gris à 0,55, texte qui dit ce qu'on attend (« Tour de B »).
12. A. Alerte orange sous 10 s gardée, signal visuel seul ; le seuil de 10 s est une valeur de la vue, sans effet de règle.

Note technique sans choix (Q7) : l'échelle d'import des SVG (`svg/scale`) se règle d'après la plus grande taille d'affichage, puis se contrôle dans `test_assets.gd` en 2b.3.

## Conséquences et vérification

- 2b.3 reconstruit l'écran selon la fiche version 1 (section « Arbre de scène cible »). Le comportement de jeu ne change pas, sauf : compteurs Réserve et Fonte, `HeroCardView` et `ClockView` retirés ; barre de temps, bulles et gris de la pièce endormie nouveaux.
- La fiche prime sur les cotes de 0030, 0032, 0035 et 0050.
- Vérification : captures en 1920×1080 et 1280×720 comparées à la maquette ; suites vertes.
- À réexaminer après le playtest J3 : lisibilité des barres de temps et des emplacements de Sources ; gris de la pièce endormie pour les daltoniens.

## Références

- `docs/fiches/ecran-de-duel.md`, `docs/maquettes/ecran-de-duel-gabarit.html`, règles 201.4.4 à 201.4.6, 201.4.10, 203.6, 208.4.6, 209.4.2d, question ouverte Q-104 (`docs/ruleset/02-questions-ouvertes.md`).
- Décisions 0030, 0032, 0035, 0045 (modifiées), 0052 (complétée), 0047, 0050, 0051.
