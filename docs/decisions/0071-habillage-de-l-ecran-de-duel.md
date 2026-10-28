# 0071 — Habillage de l'écran de duel : thème dessiné, images en remplacement

- Statut : acceptée
- Date : 2026-10-26
- Décideur : créateur du projet
- Périmètre : écran de duel, jalon J2b, étape 2b.5 (branche `feat/2b.5-habillage-ecran-de-duel`) ; vaut aussi comme principe pour 2b.6 et 2b.7

## Contexte

La charte « Vestiaire » est choisie (0070, `docs/direction-artistique/bible.md`). La fiche `docs/fiches/ecran-de-duel.md` (§ 5 et § 7) liste une trentaine d'images attendues (`ui/table.webp`, `board_frame.png`, `cell_*.png`, `source_*.png`, `counter.png`, `column_panel.png`, `time_bar_*.png`, `stack_entry.png`, `stack_empty.png`, `button_big_*.png`, `button_icon_*.png`, `modal_panel.png`, `tooltip_panel.png`, `button_modal_*.png`…). Aucune n'existe : `assets/` ne contient que `REGISTRE.md`. Le thème actuel `ui/theme/duel_theme.tres` est fait de `StyleBoxFlat`. Le cadre des assets (0051) cherche déjà une image par son nom et retombe sur le dessin si elle manque. Le créateur fera probablement des recherches Midjourney qui peuvent affiner les matières (0070).

## Options envisagées

- Option A, tout dessiné par Godot (StyleBox du thème, couleurs de la bible, coins coupés, trait d'encre, ombres en aplat décalé, Archivo et Source Serif 4) : habillage immédiat, sans attendre d'images, léger pour le Web. Limite : sans matières (grain du papier, hachures, lumière de l'arène), rendu propre mais un peu plat.
- Option B, tout en images générées par IA aux tailles de la fiche : rendu le plus riche. Coût et limite : l'étape attend une trentaine d'images ; les recherches Midjourney du créateur pourraient les rendre obsolètes.
- Option C, mélange (recommandée) : A tout de suite, puis chaque image IA déposée au nom de la fiche remplace le dessin de l'élément sans code, sur le principe de 0051 (image présente : affichée ; retirée : retour au dessin). Bénéfice : écran habillé dès 2b.5, images ajoutées au rythme du créateur. Coût : deux versions de certains éléments coexistent un temps.

## Décision

Option C, choisie par le créateur le 2026-10-26.

## Conséquences et vérification

- 2b.5 habille l'écran par le thème unique `duel_theme.tres` (aucun `theme_override`, `ui/CLAUDE.md`) selon la bible : palette, coins coupés (pas d'arrondi), trait d'encre, ombres en aplat sans flou, états normal/survol/enfoncé/désactivé, polices Archivo et Source Serif 4 (OFL, fiche § 6), déposées dans `assets/` et inscrites au `REGISTRE.md` (0051).
- Le dessin de repli suit la charte ; chaque emplacement d'image de la fiche § 7 est cherché par nom et remplace le StyleBox ou le dessin correspondant quand il existe (`StyleBoxTexture` en 9-patch aux marges de la fiche).
- Alignements de 2b.5 : pile vide sans pointillés (alvéole creusée, la charte l'emporte sur E19), marques M1 et M2 aux couleurs de la bible (`#f4c542` et `#57c77a`) ; la fiche est mise à jour à l'étape.
- Comportement et disposition des scènes inchangés.
- Vérification : suites vertes ; captures 1920×1080 et 1280×720 comparées à `docs/maquettes/ecran-de-duel-da-vestiaire.html` ; une image de test déposée puis retirée montre le remplacement et le retour au dessin.
- Réexamen : si le rendu dessiné paraît trop plat au playtest J3, ou si le poids de l'export Web (2b.8) devient gênant avec les images.

## Références

Décisions 0051 (complétée, sans modification), 0052, 0053, 0070 ; 0025 et 0027 (déjà modifiées par 0070) ; `docs/fiches/ecran-de-duel.md` ; `docs/direction-artistique/bible.md` ; roadmap étape 2b.5.
