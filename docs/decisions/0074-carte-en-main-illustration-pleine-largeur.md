# 0074 — Carte en main : illustration pleine largeur, sans bande de type

- Statut : acceptée
- Date : 2026-10-26
- Décideur : créateur du projet
- Périmètre : présentation de la carte en main (`CardView`, fiche E11) et de l'aperçu (E21), étape 2b.6 ; modifie 0027 (gabarit de la carte) et 0073 (zone d'illustration)

## Contexte

Après 0073 (pièce épurée, zone d'illustration commune de 110 px), la carte en main 158×220 devait réduire son texte à 9-10 px et caser les mots-clés dans la bande de type, où le mot « Building » disparaissait. Le créateur juge la bande de type redondante : le cadre de la carte et sa teinte disent déjà le type.

## Options envisagées

- Option A, garder la bande de type (0027) et la zone commune de 110 : le type reste écrit ; texte à la limite de lisibilité en 1280×720, mots-clés à l'étroit.
- Option B, supprimer la bande de type : l'illustration prend tout le haut de la carte ; coût, Force ou PV et bandeau du nom posés sur l'illustration, mots-clés dans le texte. Plus de place pour l'illustration et le texte ; le type ne se lit plus qu'à la teinte et au cadre.

## Décision

Option B, choix du créateur le 2026-10-26 : « supprimer la ligne qui indique Unit, le petit bandeau ; la bordure et la couleur selon le type sont une information redondante ; l'illustration peut prendre tout le dessus de la carte ; les icônes Essence et Force apparaîtront au-dessus de l'illustration, ainsi que le bandeau du nom ; les mots-clés seront présents dans le texte ».

Précisions : la vitesse d'un Spell (Réaction ou Action), qui était dans la bande de type, passe en tête du texte sous la forme d'étiquette des mots-clés, sans devenir un mot-clé de règles. Le jeton garde le nom « Jeton ». Une seule image carrée par carte (`cards/art/<id>.webp`, 0051, 0072) sert à la carte, à la pièce et à l'aperçu : image entière, même cadrage ; seules les tailles affichées diffèrent (pièce 110, carte sur toute la largeur intérieure). La zone d'illustration n'est donc plus de taille commune (0073), seulement de cadrage commun ; l'objectif de 0073, ne pas doubler la création d'assets, reste tenu.

## Conséquences et vérification

- `CardView`, l'aperçu E21 et leurs tests refaits à l'étape 2b.6 ; fiche E11, E21 et § 7, `docs/direction-artistique/instructions-ia.md` mis à jour.
- Daltonisme : le type ne repose plus que sur la teinte et l'icône de repli (question déjà ouverte par 0070, à garder ouverte).
- Réexamen au playtest J3 si le type des cartes en main se confond.

## Références

0027 (modifiée), 0051, 0070, 0071, 0072, 0073 (modifiée) ; ruleset 202.1.
