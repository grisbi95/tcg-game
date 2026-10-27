# Registre des assets

> **Rôle** : provenance de chaque fichier de `assets/` (décision 0051). Une ligne par fichier, ajoutée en même temps que lui ; `tests/test_assets.gd` vérifie que chaque fichier a sa ligne et chaque ligne son fichier.

## Rangement

| Dossier | Contenu | Format |
| --- | --- | --- |
| `cards/art/` | illustration d'une carte ou d'un Hero, nommée par son `id` de `data/cards/` (`recrue.webp`, `capitaine.webp`) | WebP, 1024 px au plus |
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
| `cards/art/bastion.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/bastion.svg` | créée pour le projet | provisoire |
| `cards/art/campement.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/campement.svg` | créée pour le projet | provisoire |
| `cards/art/capitaine.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/capitaine.svg` | créée pour le projet | provisoire |
| `cards/art/champion.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/champion.svg` | créée pour le projet | provisoire |
| `cards/art/colosse.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/colosse.svg` | créée pour le projet | provisoire |
| `cards/art/contre.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/contre.svg` | créée pour le projet | provisoire |
| `cards/art/frappe.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/frappe.svg` | créée pour le projet | provisoire |
| `cards/art/gardien.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/gardien.svg` | créée pour le projet | provisoire |
| `cards/art/heraut.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/heraut.svg` | créée pour le projet | provisoire |
| `cards/art/lame.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/lame.svg` | créée pour le projet | provisoire |
| `cards/art/levee.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/levee.svg` | créée pour le projet | provisoire |
| `cards/art/martyr.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/martyr.svg` | créée pour le projet | provisoire |
| `cards/art/palissade.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/palissade.svg` | créée pour le projet | provisoire |
| `cards/art/pillard.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/pillard.svg` | créée pour le projet | provisoire |
| `cards/art/recrue.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/recrue.svg` | créée pour le projet | provisoire |
| `cards/art/renfort.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/renfort.svg` | créée pour le projet | provisoire |
| `cards/art/soldat.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/soldat.svg` | créée pour le projet | provisoire |
| `cards/art/veteran.webp` | illustration | silhouette SVG dessinée par Claude, rendue par `tools/render_card_art.gd` | 2026-10-26 | `docs/direction-artistique/silhouettes/veteran.svg` | créée pour le projet | provisoire |
