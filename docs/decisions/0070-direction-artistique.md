# 0070 — Direction artistique

- Statut : acceptée
- Date : 2026-10-26
- Décideur : créateur du projet
- Périmètre : charte visuelle (couleurs, polices, formes, matières, états) de tout habillage de `ui/` et de tout asset (étapes 2b.5 à 2b.7)

## Contexte

Avant de générer les assets de l'écran de duel, il faut une charte unique, appliquée aux tailles de la fiche technique (`docs/fiches/ecran-de-duel.md`, décisions 0051 à 0053). Une bible visuelle (brouillon du 21 octobre 2026) a été reprise seule dans `docs/direction-artistique/bible.md` et recalée sur la fiche ; le cahier des charges technique et la maquette V3 de l'ancienne branche sont supplantés par la fiche et 0051. Deux maquettes habillées, sur la géométrie exacte du gabarit et avec les cartes du deck de test : `docs/maquettes/ecran-de-duel-da-vestiaire.html` et `docs/maquettes/ecran-de-duel-da-affiche.html`. Points communs : coins coupés, trait d'encre, ombres en aplat décalé, aucun texte dans une image, deux polices libres (OFL) au plus.

## Options envisagées

- A « Vestiaire » : la bible telle quelle. Table sombre et chaude (`#1c1916`), plateau et cartes en papier (`#efe5cf`), encre `#15120f`, bandes de type hachurées, lumière d'arène d'en haut ; Archivo et Source Serif 4. Bénéfice : reposante sur un long duel, couleurs franches (A, B, Essence, surligné, choisi) qui ressortent seules, proche du gabarit donc habillage simple. Coût : plus classique, le caractère repose sur les illustrations.
- B « Affiche » : page de bande dessinée imprimée. Table claire tramée (`#ece1c8`), trait épais, grandes ombres d'encre ; Bricolage Grotesque et Literata. Bénéfice : très singulière, lisible en plein jour. Coût : fatigue dans le noir et sur un long duel, surligné jaune moins visible, contredit la bible (fond sombre), plus loin du gabarit.

## Décision

Option A « Vestiaire », choisie par le créateur le 2026-10-26 (recommandée). Le créateur retravaillera probablement la direction artistique avec Midjourney dans une autre session : la charte fixe les invariants (palette des couleurs franches de jeu, coins coupés, encre, ombres en aplat, aucun texte dans l'image, polices, tailles de la fiche) ; ces recherches pourront affiner le traitement des illustrations, des matières et des teintes sourdes dans ce cadre.

## Conséquences et vérification

- `docs/direction-artistique/bible.md` passe de brouillon à référence ; la maquette A est la référence visuelle, B reste comme option écartée ; les instructions de référence pour l'IA sont écrites dans `docs/direction-artistique/` à la même étape.
- Les teintes de type de 0027 sont remplacées par celles de la bible (Unit `#a8b88f`, Building `#cfae74`, Spell `#9ea6c4`, Gear `#c98f72`, Hero `#c79aa3`) ; couleurs de joueur : A `#2f6fd6`, B `#d43b2f`, le rouge ne sert qu'à B : 0027 modifiée par 0070.
- 0025 (aspect sobre) est réexaminée comme le demandait la roadmap J2b : modifiée par 0070 pour l'aspect ; le thème Godot par défaut est proscrit.
- Fiche : § 6 reçoit Archivo et Source Serif 4. Contradiction connue : la bible veut une alvéole creusée pour un emplacement vide, la fiche E14 disait « contour pointillé » ; la charte l'emporte pour l'aspect et E14 est mise à jour. Les pointillés restants de la fiche (pile vide, E19) et les jaune/vert des marques M1 et M2 (`#f2c14e`, `#4ecb71`, contre `#f4c542` et `#57c77a` de la bible) restent à aligner à l'étape 2b.5.
- Reprise le 2026-10-28 après J2c : numérotée 0070 (le numéro 0054, pris à l'origine, est celui de la décision du jalon J2c) ; casting de la bible recalé sur les quatre Heroes du catalogue (`ruleset/50-cartes/heroes.md`). Les maquettes gardent le Capitaine du deck de test de l'époque.
- À trancher : le daltonisme (bible, États).
- Vérification : maquette A et assets des étapes 2b.5 à 2b.7 conformes à la bible ; capture de l'écran en 1920×1080 et 1280×720.
- À réexaminer : si les recherches Midjourney changent un invariant (palette de jeu, fond sombre, formes), ou si le playtest J3 montre un plateau illisible.

## Références

`docs/direction-artistique/bible.md` ; `docs/maquettes/ecran-de-duel-da-vestiaire.html` et `-da-affiche.html` ; `docs/fiches/ecran-de-duel.md` ; décisions 0025, 0027, 0051, 0052, 0053 ; roadmap étape 2b.4.
