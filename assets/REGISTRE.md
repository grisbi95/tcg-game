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
