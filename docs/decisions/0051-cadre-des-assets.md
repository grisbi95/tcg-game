# 0051 — Cadre des assets : dossier `assets/` et illustration retrouvée par l'identifiant de la carte

- Statut : acceptée ; complétée par 0052
- Date : 2026-10-23
- Décideur : créateur du projet
- Périmètre : rangement, nommage, formats et réglages d'import des images, polices et icônes ; lien entre une carte et son illustration ; repli quand un asset manque ; registre de provenance (étape 2b.1, jalon J2b)

## Contexte

Le jeu a un aspect prototype, tout dessiné par code : thème unique `ui/theme/duel_theme.tres`, icônes tracées par `ui/theme/duel_icons.gd`, aucune image dans le dépôt. La décision 0027 (qui remplace 0025) remplace l'illustration par l'icône du type tant qu'il n'y en a pas. Le créateur insère avant le playtest J3 un jalon d'habillage : illustrations, fonds et cadres générés par IA, polices libres, icônes vectorielles. Contraintes : export Web d'abord (GL Compatibility, poids de l'export) ; couches `data ← rules ← ai ← app ← ui`, le moteur ne connaît aucune image ; tout nouveau dossier racine se valide d'abord.

## Options envisagées

- Option A : dossier racine `assets/` rangé par sorte, illustration d'une carte nommée par son identifiant (`assets/cards/art/<id>.webp`) ; déposer le fichier suffit. Bénéfice : habitude courante sous Godot, code et images séparés, catalogue inchangé. Coût : un dossier racine de plus. Limite : une image par carte, ni partage ni variante.
- Option B : même rangement sous `ui/assets/`. Bénéfice : aucun dossier racine. Coût : images et scripts mélangés dans `ui/`.
- Option C : champ `art` dans le JSON des cartes. Bénéfice : souple (partage, variantes). Coût : touche le format du catalogue (0010) et fait entrer un chemin d'image dans `rules/` (`CardDefinition`).

## Décision

Option A, choisie par le créateur le 2026-10-23 ; elle valide le dossier racine `assets/`.

- Arborescence : `assets/cards/art/` (illustrations, dont celle du Hero, nommées par l'identifiant du JSON), `assets/cards/frames/` (cadres par type, dos de carte), `assets/ui/` (fonds, plateau, cases, boutons, fenêtres, pendule, pile), `assets/icons/` (SVG), `assets/fonts/` (polices libres, licence OFL ou équivalente), `assets/REGISTRE.md`.
- Nommage : `snake_case`, sans espace ni accent ; un état d'élément interactif en suffixe (`_normal`, `_hover`, `_pressed`, `_disabled`).
- Formats : illustrations et fonds en WebP, 1024 px au plus sur le grand côté ; cadres, boutons et fenêtres en PNG découpé en 9 parties (`StyleBoxTexture`) ; icônes en SVG ; polices TTF, OTF ou WOFF2.
- Import : sans mipmaps pour l'interface, compression sans perte ou avec perte (WebP), jamais de compression VRAM (Web, GL Compatibility). `project.godot` n'est pas modifié ; un test contrôle les réglages lus dans les `.import` du dossier.
- Lien et repli : un utilitaire de `ui/theme/` (`RefCounted`, sans scène) cherche l'asset par son nom (`ResourceLoader.exists`) et rend le repli s'il manque : l'icône du type pour une illustration (0027), le dessin de `DuelIcons` pour une icône, le style actuel du thème pour un cadre. Aucun fichier provisoire n'est nécessaire, le repli tient ce rôle. Le moteur et `data/` ne connaissent aucune image.
- Thème : textures et polices entrent par le thème unique (variations existantes, `StyleBoxTexture` à la place de `StyleBoxFlat`), jamais par `theme_override` dans une scène (`ui/CLAUDE.md`).
- Registre `assets/REGISTRE.md` : une ligne par fichier avec fichier, sorte, outil (modèle d'IA ou source), date, instruction donnée à l'IA ou URL, droits ou licence, statut provisoire ou définitif. Les conditions d'usage de l'outil d'IA sont notées pour pouvoir remplacer une image plus tard.
- Test `tests/test_assets.gd` (à écrire à l'étape 2b.1) : noms valides, chaque fichier au registre et chaque ligne du registre à un fichier, chaque illustration nommée par une carte ou un Hero existant, réglages d'import, taille maximale.

## Conséquences et vérification

- `assets/` s'ajoute à l'arborescence du `CLAUDE.md` racine (§5) ; `ui/CLAUDE.md` gagnera une ligne sur le repli des assets. Le filtre d'export Web (`export_presets.cfg`, `export_filter="all_resources"`) embarque déjà `assets/`, le registre n'étant pas une ressource ; l'étape 2b.6 mesurera le poids de l'export.
- Vérification : déposer une illustration au nom d'une carte la fait apparaître dans `CardView`, `PieceView` et `HoverPreview` sans code ; la retirer rend l'icône du type ; tests verts.
- Réexamen si une carte doit partager ou varier son illustration (alors option C), ou si le poids de l'export Web gêne le chargement des playtests (étape 2b.6).

## Références

- Décisions 0010 (forme du catalogue), 0025 (remplacée), 0027 (complétée par cette décision), 0005 (export Web).
- `docs/roadmap.md` étape 2b.1 ; `ui/theme/duel_theme.tres`, `ui/theme/duel_icons.gd`, `ui/CLAUDE.md`.
