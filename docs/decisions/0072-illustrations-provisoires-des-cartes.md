# 0072 — Illustrations provisoires des cartes : silhouettes dessinées

- Statut : acceptée
- Date : 2026-10-26
- Décideur : créateur du projet
- Périmètre : illustrations des 17 cartes et du Hero Capitaine de `data/cards/test_deck.json` (18 images), jalon J2b, étape 2b.6 (branche `feat/2b.6-cartes`)

## Contexte

L'étape 2b.6 habille les cartes : cadres par type, dos, pastilles, icônes de type et de mots-clés, 18 illustrations. Le cadre des assets (0051) affiche `assets/cards/art/<id>.webp` dès qu'il existe, sinon l'icône du type. La bible (`docs/direction-artistique/bible.md`) et `docs/direction-artistique/instructions-ia.md` prévoient des illustrations générées (Midjourney), que le créateur fera plus tard. Les cadres suivent déjà 0071 (dessin du thème, image en remplacement).

## Options envisagées

- Option A, le créateur génère les 18 illustrations avec Midjourney pendant l'étape : vrai rendu tout de suite. Limite : l'étape attend 18 images, grosse tâche pour le créateur.
- Option B, silhouettes provisoires dessinées par Claude en vectoriel (encre sur fond de la teinte du type, style de la bible), que les images Midjourney remplacent une à une sans code (recommandée) : cartes reconnaissables tout de suite, rien n'attend le créateur. Limite : formes simples, le vrai rendu vient plus tard.
- Option C, aucune illustration à l'étape, l'icône du type reste au centre : étape la plus courte. Limite : pas de personnage sur les cartes jusqu'aux images du créateur.

## Décision

Option B, choisie par le créateur le 2026-10-26.

## Conséquences et vérification

- Une silhouette par carte et par Hero, sources SVG dans `docs/direction-artistique/silhouettes/<id>.svg` (hors export Web), sur la grille et dans les consignes de la bible et d'`instructions-ia.md` § 3 : un seul personnage ou objet, entier, dans les 90 % centraux, fond uni de la teinte du type, trait d'encre, aplats, aucun texte, lisible à 40 px de haut.
- Rendues en `assets/cards/art/<id>.webp` (carré, 1024 px au plus, format de 0051) par l'outil Godot headless `tools/render_card_art.gd` (Godot lit le SVG et écrit le WebP, aucun outil externe), relançable.
- Chaque image a sa ligne dans `assets/REGISTRE.md`, outil « silhouette SVG dessinée par Claude », statut `provisoire`. Une image Midjourney du créateur remplace le WebP de même nom et sa ligne passe à l'outil réel ; la source SVG peut alors être supprimée.
- Aucun code de vue nouveau pour l'affichage : 0051 suffit.
- Vérification : les 18 fichiers présents et enregistrés (`test_assets.gd`), cartes et pièces lisibles en 1280×720 dans la main, au plateau et dans l'aperçu.
- Réexamen : quand le créateur livre ses illustrations, ou si les silhouettes nuisent à la lisibilité au playtest J3.

## Références

Décisions 0027, 0051, 0070, 0071 ; complète 0051 sans la modifier ; `docs/direction-artistique/bible.md` ; `docs/direction-artistique/instructions-ia.md` ; roadmap étape 2b.6.
