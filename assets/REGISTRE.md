# Registre des assets

> **Rôle** : provenance de chaque fichier de `assets/` (décision 0051). Une ligne par fichier, ajoutée en même temps que lui ; `tests/test_assets.gd` vérifie que chaque fichier a sa ligne et chaque ligne son fichier.

## Rangement

| Dossier | Contenu | Format |
| --- | --- | --- |
| `cards/frames/` | cadres par type, dos de carte | PNG découpé en 9 parties |
| `ui/` | fonds, plateau, cases, boutons, fenêtres, pendule, pile | WebP (fonds), PNG en 9 parties (cadres) |
| `icons/` | icônes, nommées comme dans `DuelIcons.Icon` (`unit.svg`, `heart.svg`, `source.svg`), dessinées en blanc : le jeu les teinte | SVG |
| `fonts/` | polices libres (licence OFL ou équivalente) | TTF, OTF, WOFF2 |

Noms en `snake_case`, sans espace ni accent ; l'état d'un élément interactif en suffixe (`_normal`, `_hover`, `_pressed`, `_disabled`). Un dossier se crée à son premier fichier. Réglages d'import : sans mipmaps, compression sans perte ou avec perte, jamais VRAM. Un asset absent garde le dessin actuel du jeu.

## Fichiers

Fichier relatif à `assets/` ; statut `provisoire` ou `définitif`.

| Fichier | Sorte | Outil ou source | Date | Instruction ou URL | Droits | Statut |
| --- | --- | --- | --- | --- | --- | --- |
| `fonts/archivo.ttf` | police (variable, graisse et largeur) | Google Fonts, `ofl/archivo/Archivo[wdth,wght].ttf` | 2026-10-26 | https://github.com/google/fonts/tree/main/ofl/archivo | OFL 1.1, `fonts/archivo_ofl.txt` | définitif |
| `fonts/archivo_ofl.txt` | licence | Google Fonts, `ofl/archivo/OFL.txt` | 2026-10-26 | https://github.com/google/fonts/tree/main/ofl/archivo | texte de la licence OFL 1.1 | définitif |
| `fonts/source_serif_4.ttf` | police (variable, graisse et taille optique) | Google Fonts, `ofl/sourceserif4/SourceSerif4[opsz,wght].ttf` | 2026-10-26 | https://github.com/google/fonts/tree/main/ofl/sourceserif4 | OFL 1.1, `fonts/source_serif_4_ofl.txt` | définitif |
| `fonts/source_serif_4_ofl.txt` | licence | Google Fonts, `ofl/sourceserif4/OFL.txt` | 2026-10-26 | https://github.com/google/fonts/tree/main/ofl/sourceserif4 | texte de la licence OFL 1.1 | définitif |
| `icons/building.svg` | icône, logo du type Building (remplace l'illustration de chaque carte de ce type) | SVG dessiné par Claude, grille de 24 | 2026-10-28 | forme pleine blanche, coins coupés, teintée par le jeu | créée pour le projet | provisoire |
| `icons/hero.svg` | icône, logo du type Hero (remplace l'illustration de chaque carte de ce type) | SVG dessiné par Claude, grille de 24 | 2026-10-28 | forme pleine blanche, coins coupés, teintée par le jeu | créée pour le projet | provisoire |
| `icons/spell.svg` | icône, logo du type Spell (remplace l'illustration de chaque carte de ce type) | SVG dessiné par Claude, grille de 24 | 2026-10-28 | forme pleine blanche, coins coupés, teintée par le jeu | créée pour le projet | provisoire |
| `icons/unit.svg` | icône, logo du type Unit (remplace l'illustration de chaque carte de ce type) | SVG dessiné par Claude, grille de 24 | 2026-10-28 | forme pleine blanche, coins coupés, teintée par le jeu | créée pour le projet | provisoire |
