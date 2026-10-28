# 0072 — Illustrations provisoires des cartes : un logo par type

- Statut : acceptée
- Date : 2026-10-26, choix revu le 2026-10-28
- Décideur : créateur du projet
- Périmètre : illustration des cartes et des Heroes du catalogue de playtest et du deck de test, jalon J2b, étape 2b.6 (branche `feat/2b.6-cartes`)

## Contexte

L'étape 2b.6 habille les cartes : cadres par type, dos, pastilles, icônes de type et de mots-clés, illustrations. Le cadre des assets (0051) affiche `assets/cards/art/<id>.webp` dès qu'il existe, sinon l'icône du type, dessinée par `DuelIcons` ou remplacée par `assets/icons/<type>.svg`. La bible (`docs/direction-artistique/bible.md`) et `docs/direction-artistique/instructions-ia.md` prévoient des illustrations générées (Midjourney), que le créateur fera plus tard. Le catalogue de J2c compte 48 cartes et 4 Heroes.

## Options envisagées

- Option A, le créateur génère les illustrations avec Midjourney pendant l'étape : vrai rendu tout de suite. Limite : l'étape attend une image par carte, grosse tâche pour le créateur.
- Option B, une silhouette vectorielle par carte dessinée par Claude, que les images Midjourney remplacent une à une : cartes reconnaissables tout de suite. Limite : une silhouette par carte, soit 52 pour le catalogue, pour un rendu provisoire. Retenue le 2026-10-26 pour les 18 cartes du deck de test, puis abandonnée.
- Option C, un logo simple par type à la place de l'illustration : Unit, Building, Spell et Hero, quatre fichiers pour tout le catalogue. Limite : les cartes d'un même type se ressemblent jusqu'aux images du créateur ; le nom et le texte les distinguent.

## Décision

Option C, choisie par le créateur le 2026-10-28 : « juste des petits logos qui remplaceront l'illustration ; une pour les units, une pour les buildings, une pour les sorts et une pour les capitaines ; quelque chose de simple ». Elle remplace l'option B du 2026-10-26.

## Conséquences et vérification

- Quatre logos `assets/icons/unit.svg`, `building.svg`, `spell.svg` et `hero.svg` : formes pleines blanches sur la grille de 24 de `DuelIcons`, coins coupés (bible), aucun texte, teintées par le jeu à l'encre du type ; rendus en 256 px à l'import pour rester nets dans l'aperçu.
- Aucun code de vue nouveau : le repli de 0051 montre l'icône du type à la place de l'illustration, sur la carte, la pièce et l'aperçu, et prend le fichier de `assets/icons/` quand il existe. Le Gear garde l'icône dessinée par `DuelIcons`.
- Les 18 silhouettes de l'option B, leurs sources SVG et l'outil `tools/render_card_art.gd` sont retirés ; aucune image dans `assets/cards/art/`.
- Une illustration Midjourney du créateur, déposée en `assets/cards/art/<id>.webp` avec sa ligne au registre, remplace le logo pour sa carte seulement, sans code.
- Vérification : les quatre fichiers présents et enregistrés (`test_assets.gd`) ; cartes et pièces lisibles en 1280×720 dans la main, au plateau et dans l'aperçu.
- Réexamen : quand le créateur livre ses illustrations, ou si le playtest J3 montre qu'on confond les cartes d'un même type au plateau.

## Références

Décisions 0027, 0051, 0070, 0071, 0073, 0074 ; complète 0051 sans la modifier ; `docs/direction-artistique/bible.md` ; `docs/direction-artistique/instructions-ia.md` ; roadmap étape 2b.6.
