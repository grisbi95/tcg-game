# 0073 — Pièce du plateau épurée : illustration et Force ou PV

- Statut : acceptée ; modifiée par 0074 ; modifie l'affichage de 0058 (mots-clés accordés)
- Date : 2026-10-26
- Décideur : créateur du projet
- Périmètre : présentation de la pièce du plateau (`PieceView`, fiche E06 et E07), étape 2b.6 ; modifie 0027 sur la pièce seulement

## Contexte

La décision 0027 voulait pour la pièce une mini-carte carrée : nom, Force en haut à droite, illustration, bandeau de type portant les étiquettes de mots-clés. Avec les illustrations carrées (0072) et l'habillage « Vestiaire » (0070, 0071), le créateur juge le bandeau et le libellé de type inutiles : la teinte du type se voit déjà, et le texte du survol (aperçu E21, bulles E27) donne déjà mots-clés et état.

## Options envisagées

- Option A, garder la mini-carte de 0027 (nom, bandeau de type, mots-clés) : tout se lit sans survol ; pièce chargée, illustration réduite, noms longs coupés.
- Option B, pièce épurée : l'illustration carrée remplit la pièce, avec seulement la pastille de Force (Units, Buildings, jetons) ou le cœur des PV (Hero) ; le reste au survol. Plateau lisible, illustrations mises en valeur ; il faut survoler pour lire nom, type et mots-clés.

## Décision

Option B, choix du créateur le 2026-10-26 : « pas besoin de label de type de carte, la couleur le définit déjà sur le plateau ; juste l'illustration format carré et les logos Force ou PV ; le texte du survol donne les indications ».

Restent sur la pièce : le liseré de camp (0027, 0030), les marques jouable, choisie et survol, l'état endormi en gris (201.4.11), la bande du Gear attaché (E08, un état et non un libellé). Sans illustration, l'icône du type au centre sur la teinte du type. La carte en main (E11) et l'aperçu (E21) gardent nom, coût, type, texte et mots-clés, inchangés.

Zone d'illustration commune (précision du créateur, même jour, « pour ne pas doubler la création d'assets ») : la carte en main et la pièce montrent la même illustration carrée, à la même taille affichée et au même cadrage, image entière ; un seul fichier `cards/art/<id>.webp` sert aux deux, l'aperçu le montre au double. La taille commune est écrite dans la fiche (E06, E11, § 7).

## Conséquences et vérification

- `PieceView` et ses tests adaptés à l'étape 2b.6 ; fiche `docs/fiches/ecran-de-duel.md` E06 et E07 mises à jour à la même étape.
- Le pilier « la puissance reste lisible » est tenu par la pastille de Force.
- Le jeton n'a plus de nom « Jeton » affiché sur la pièce ; il se reconnaît au survol.
- Mots-clés reçus (Assaut et Rempart accordés par un effet, un Gear ou une aura, 210.4, décision 0058) : la ligne que J2c posait sur la pièce est retirée ; ils paraissent au survol, dans les bulles de l'aperçu, avec leur valeur actuelle (`CardText.piece_keywords`, `InfoBubble.list_for_piece`). Choix du créateur le 2026-10-28, à la reprise de 2b.6 après J2c (option « au survol » contre une petite icône sur la pièce).
- Réexamen : si le playtest J3 montre qu'on ne reconnaît pas les pièces sans survol (mots-clés comme Rempart ou Assaut en particulier).

## Références

0027 (modifiée), 0030, 0070, 0071, 0072 ; ruleset 202.1, 202.4, 201.4.11.
